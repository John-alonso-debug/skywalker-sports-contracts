pragma solidity ^0.6.2;
import "./ERC20Wrapper.sol";
import "./IShareToken.sol";

pragma experimental ABIEncoderV2;

/**
 * @dev This is a factory that creates Wrappers around ERC1155 shareTokens generated by Augur
 * @author yashnaman
 * as shares on outcomes of a markets.
 * For every outcome there will be one wrapper.
 */
contract AugurFoundry is ERC1155Receiver {
    using SafeMath for uint256;
    IShareToken public shareToken;
    IERC20 public cash;
    address public augur;
    //@dev this makes this foundry compatable with only yes/no markets
    //TODO: figure out a way to do this dynamically
    uint256[] public OUTCOMES = [0, 1, 2];
    uint256 public numTicks;

    mapping(uint256 => address) public wrappers;

    event WrapperCreated(uint256 indexed tokenId, address tokenAddress);

    /**@dev sets value for {shareToken} and {cash}
     * @param _shareToken address of shareToken associated with a augur universe
     *@param _cash DAI
     */
    constructor(
        IShareToken _shareToken,
        IERC20 _cash,
        address _augur,
        uint256 _numTicks
    ) public {
        cash = _cash;
        shareToken = _shareToken;
        augur = _augur;
        numTicks = _numTicks;
        // //approve for all to the augur
        // _shareToken.approveForAll(_augur, true);
        _cash.approve(augur, uint256(-1));
    }

    /**@dev creates new ERC20 wrappers for a outcome of a market
     *@param _tokenId token id associated with a outcome of a market
     *@param _name a descriptive name mentioning market and outcome
     *@param _symbol symbol for the ERC20 wrapper
     *@param decimals decimals for the ERC20 wrapper
     */
    function newERC20Wrapper(
        uint256 _tokenId,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        require(wrappers[_tokenId] == address(0), "Wrapper already created");
        ERC20Wrapper erc20Wrapper = new ERC20Wrapper(
            address(this),
            shareToken,
            cash,
            _tokenId,
            _name,
            _symbol,
            _decimals
        );
        wrappers[_tokenId] = address(erc20Wrapper);
        emit WrapperCreated(_tokenId, address(erc20Wrapper));
    }

    /**@dev creates new ERC20 wrappers for multiple tokenIds*/
    function newERC20Wrappers(
        uint256[] memory _tokenIds,
        string[] memory _names,
        string[] memory _symbols,
        uint8[] memory _decimals
    ) public {
        require(
            _tokenIds.length == _names.length &&
                _tokenIds.length == _symbols.length
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            newERC20Wrapper(_tokenIds[i], _names[i], _symbols[i], _decimals[i]);
        }
    }

    /**@dev A function that wraps ERC1155s shareToken into ERC20s
     * Requirements:
     *
     * -  msg.sender has setApprovalForAll to this contract
     * @param _tokenId token id associated with a outcome of a market
     * @param _account account the newly minted ERC20s will go to
     * @param _amount  amount of tokens to be wrapped
     */
    function wrapTokens(
        uint256 _tokenId,
        address _account,
        uint256 _amount
    ) public {
        ERC20Wrapper erc20Wrapper = ERC20Wrapper(wrappers[_tokenId]);
        shareToken.safeTransferFrom(
            msg.sender,
            address(erc20Wrapper),
            _tokenId,
            _amount,
            ""
        );
        erc20Wrapper.wrapTokens(_account, _amount);
    }

    /**@dev A function that mints  ERC1155s shareToken by speding cash tokens and wraps
     * ERC1155s shareToken into ERC20s in one transaction
     * Requirements:
     *
     * -  msg.sender has given atleast of _amount * numTicks aprrova of cash to this contract
     * -  as of now this only supporsts yes/no market
     * @param _market The market to purchase complete sets in
     * @param _account The account receiving the complete sets
     * @param _amount The number of complete sets to purchase
     */
    function mintWrap(
        address _market,
        address _account,
        uint256 _amount
    ) public {
        cash.transferFrom(msg.sender, address(this), _amount.mul(numTicks));
        shareToken.buyCompleteSets(_market, address(this), _amount);

        uint256[] memory tokenIds = shareToken.getTokenIds(_market, OUTCOMES);
        for (uint8 i = 0; i < tokenIds.length; i++) {
            ERC20Wrapper erc20Wrapper = ERC20Wrapper(wrappers[tokenIds[i]]);
            shareToken.safeTransferFrom(
                address(this),
                address(erc20Wrapper),
                tokenIds[i],
                _amount,
                ""
            );
            erc20Wrapper.wrapTokens(_account, _amount);
        }
    }

    /**@dev A function that burns ERC20s and gives back ERC1155s
     * Requirements:
     *
     * - msg.sender has setApprovalForAll to true for shareToken to this contract address
     * - msg.sender atleast _amount of ERC20 tokens associated with tokenIds of _market.
     * - if the market has finalized then it is  advised that you call claim() on ERC20Wrapper
     * contract associated with the winning outcome
     * @param _market The market to sell complete sets in
     * @param _recipient The recipient of funds from the sale
     * @param _amount The number of complete sets to sell
     * @param _fingerprint Fingerprint of the filler used to naively restrict affiliate fee dispursement
     */
    function unwrapRedeem(
        address _market,
        address _recipient,
        uint256 _amount,
        bytes32 _fingerprint
    ) public {
        uint256[] memory tokenIds = shareToken.getTokenIds(_market, OUTCOMES);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            unWrapTokens(tokenIds[i], _amount, address(this));
        }
        shareToken.sellCompleteSets(
            _market,
            address(this),
            _recipient,
            _amount,
            _fingerprint
        );
    }

    /**@dev A function that burns ERC20s and gives back ERC1155s
     * Requirements:
     *
     * - msg.sender has more than _amount of ERC20 tokens associated with _tokenId.
     * - if the market has finalized then it is  advised that you call claim() on ERC20Wrapper
     * contract associated with the winning outcome
     * @param _tokenId token id associated with a outcome of a market
     * @param _amount amount of tokens to be unwrapped
     */
    function unWrapTokens(
        uint256 _tokenId,
        uint256 _amount,
        address _receipient
    ) public {
        ERC20Wrapper erc20Wrapper = ERC20Wrapper(wrappers[_tokenId]);
        erc20Wrapper.unWrapTokens(msg.sender, _receipient, _amount);
    }

    /**@dev wraps multiple tokens */
    function wrapMultipleTokens(
        uint256[] memory _tokenIds,
        address _account,
        uint256[] memory _amounts
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            wrapTokens(_tokenIds[i], _account, _amounts[i]);
        }
    }

    /**@dev unwraps multiple tokens */
    function unWrapMultipleTokens(
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        address _receiver
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            unWrapTokens(_tokenIds[i], _amounts[i], _receiver);
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
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }
}
