pragma solidity ^0.4.11;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract ExampleContract is usingOraclize {

    string public ETHUSD;
    address public owner;
    event LogConstructorInitiated(string nextStep);
    event LogPriceUpdated(string price);
    event LogNewOraclizeQuery(string description);

    mapping (bytes32 => bool) public pendingQueries;
    
    mapping (address => uint) public depositesInUSD;

    function ExampleContract() payable {
        LogConstructorInitiated("Constructor was initiated. Call 'updatePrice()' to send the Oraclize Query.");
        owner = msg.sender;
    }
    
    function stringToUint(string s) constant returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();
        require (pendingQueries[myid] == true);
        ETHUSD = result;
        LogPriceUpdated(result);
        delete pendingQueries[myid]; // This effectively marks the query id as processed.
    }

    function updatePrice() payable {
        if (oraclize_getPrice("URL") > this.balance) {
            LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            bytes32 queryId = oraclize_query("URL", "json(https://api.gdax.com/products/ETH-USD/ticker).price");
            pendingQueries[queryId] = true;
        }
    }
    
    function () payable {
        require (msg.value > 0);
        updatePrice();
        uint ETHUSDuint = stringToUint(ETHUSD);
        if (msg.sender != owner)
            depositesInUSD[msg.sender] += ( msg.value * ETHUSDuint ) / 10**24;
    }
}
