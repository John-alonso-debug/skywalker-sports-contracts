pragma solidity ^0.6.2;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "./IShareToken.sol";

/**
 * @dev This is an Wrapper around ERC1155 shareTokens generated by Augur
 * @author yashnaman
 * as shares on a outcome of a market.
 * For every outcome there will be one wrapper.
 * The approch here is simple. It gets ERC1155 token and mints ERC20.
 * It burns ERC20s and gives back the ERC11555s.
 * AugurFoundry passed in the constructor has special permission to mint and burn.
 */
contract ERC20Wrapper is ERC20, ERC1155Receiver {
    uint256 public tokenId;
    IShareToken public shareToken;
    IERC20 public cash;
    address public augurFoundry;

    /**
     * @dev sets values for
     * @param _augurFoundry A trusted factory contract so that users can wrap multiple tokens in one
     * transaction without giving individual approvals
     * @param _shareToken address of shareToken for which this wrapper is for
     * @param _cash DAI
     * @param _tokenId id of market outcome this wrapper is for
     * @param _name a descriptive name mentioning market and outcome
     * @param _symbol symbol
     * @param _decimals decimals
     */
    constructor(
        address _augurFoundry,
        IShareToken _shareToken,
        IERC20 _cash,
        uint256 _tokenId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        augurFoundry = _augurFoundry;
        tokenId = _tokenId;
        shareToken = _shareToken;
        cash = _cash;
    }

    /**@dev A function that gets ERC1155s and mints ERC20s
     * Requirements:
     *
     * - if the msg.sender is not augurFoundry then it needs to have given setApprovalForAll
     *  to this contract (if the msg.sender is augur foundry then we trust it and know that
     *  it would have transferred the ERC1155s to this contract before calling it)
     * @param _account account the newly minted ERC20s will go to
     * @param _amount amount of tokens to be wrapped
     */
    function wrapTokens(address _account, uint256 _amount) public {
        if (msg.sender != augurFoundry) {
            shareToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                _amount,
                ""
            );
        }
        _mint(_account, _amount);
    }

    /**@dev A function that burns ERC20s and gives back ERC1155s
     * Requirements:
     *
     * - if the msg.sender is not augurFoundry or _account then the caller must have allowance for ``_account``'s tokens of at least
     * `amount`.
     * - if the market has finalized then claim() function should be called.
     * @param _holder account that has the wrapped tokens
     * @param _recipient account that will get the sharetokens
     * @param _amount amount of tokens to be unwrapped
     */
    function unWrapTokens(
        address _holder,
        address _recipient,
        uint256 _amount
    ) public {
        if (msg.sender != _holder && msg.sender != augurFoundry) {
            uint256 decreasedAllowance = allowance(_holder, msg.sender).sub(
                _amount,
                "ERC20: burn amount exceeds allowance"
            );
            _approve(_holder, msg.sender, decreasedAllowance);
        }
        _burn(_holder, _amount);

        shareToken.safeTransferFrom(
            address(this),
            _recipient,
            tokenId,
            _amount,
            ""
        );
    }

    /**@dev A function that burns ERC20s and gives back DAI
     * It will return _account DAI if the outcome for which this wrapper is for
     * is a winning outcome.
     * Requirements:
     *  - if msg.sender is not {_account} then {_account} should have given allowance to msg.sender
     * of at least balanceOf(_account)
     * This is to prevent cases where an unknowing contract has the balance and someone claims
     * winning for them.
     * - Not really a requirement but...
     *  it makes more sense to call it when the market has finalized.
     *
     * @param _account account for which DAI is being claimed
     */
    function claim(address _account) public {
        /**@notice checks if the proceeds were claimed before. If not then claims the proceeds */
        if (shareToken.balanceOf(address(this), tokenId) != 0) {
            shareToken.claimTradingProceeds(
                shareToken.getMarket(tokenId),
                address(this),
                ""
            );
        }
        uint256 cashBalance = cash.balanceOf(address(this));
        /**@notice If this is a winning outcome then give the user thier share of DAI */
        if (cashBalance != 0) {
            uint256 userShare = (cashBalance.mul(balanceOf(_account))).div(
                totalSupply()
            );
            if (msg.sender != _account) {
                uint256 decreasedAllowance = allowance(_account, msg.sender)
                    .sub(
                    balanceOf(_account),
                    "ERC20: burn amount exceeds allowance"
                );
                _approve(_account, msg.sender, decreasedAllowance);
            }
            _burn(_account, balanceOf(_account));
            require(cash.transfer(_account, userShare));
        }
    }

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        /**@notice To make sure that no other tokenId other than what this ERC20 is a wrapper for is sent here*/
        require(id == tokenId, "Not acceptable");
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        /**@notice This is not allowed. Just transfer one predefined id here */
        return "";
    }
}