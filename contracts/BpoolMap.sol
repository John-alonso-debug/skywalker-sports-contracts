pragma solidity >=0.6.0 <0.8.0;

contract BpoolMaps{
    
    struct BMaps{
        address owner;
        address bpool;
        
    }
    
    //first address is market address , second is BMaps object
   mapping(address=> BMaps) public marketsMap;
    

    event Update(address market,address owner,address bpool);
    
     function createMap(address _market,address _pool)  public  returns (address){
        
        BMaps storage market = marketsMap[_market];
        
         if(market.owner == address(0))
        {
            market.owner = msg.sender;
            market.bpool = _pool;
            emit Update(_market,msg.sender, _pool);
        // market.bpool = _pool;
         return market.owner;
        }
        require(market.owner == msg.sender, "You are not allow to modify.");
       
        market.bpool = _pool;
       
        
        emit Update(_market ,msg.sender, _pool);
        // market.bpool = _pool;
        return market.owner;
        
        
    }
    
 
    
    
    
   
}