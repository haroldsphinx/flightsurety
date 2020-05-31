pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => bool) private authorizedCallers;

    uint256 internal totalPaidAirlines = 0;


    mapping(address => Airline) private airlines;

    enum InsuranceState {
        Bought,
        Claimed
    }

    struct Insurance {
        string flight;
        uint256 amount;
        uint256 payoutAmount;
        InsuranceState state;
    }

    mapping(address => mapping(string => Insurance)) private passengerInsurances;
    mapping(address => uint256) private passengerBalances;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public {
        contractOwner = msg.sender;
        airlines[contractOwner] = Airline(contractOwner, AirlineState.Paid, "First Airline", 0);
        totalPaidAirlines++;
    }

    struct Flight {
        address airline;
        bool isRegistered;
        uint256 timestamp;
        string flight;
        address[] buyeraddress;
        uint8 statuscode;
        mapping (address => uint256) buyers;
        uint256 credits;
    }


    mapping(address => bool) private registeredAirlines;
    mapping(bytes32 => Flight) private flights;

    bytes32[] public flightKeys;

    event RegisteredAirline(address airline, uint airlinesCount);
    event FlightAdded(address airline, bytes32 flightkey, string flight);

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier isAuthorized() {
        require(authorizedCallers[msg.sender] || (msg.sender == contractOwner), "Unathorized Contract Caller");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() public view returns(bool) {
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    //set calleraruthrozed status
    function authorizeCaller(address callerAddress) external requireContractOwner returns (bool) {
        authorizedCallers[callerAddress] = true;
        return authorizedCallers[callerAddress];
    }

    function unauthorizeCaller(address callerAddress) external requireContractOwner returns (bool) {
        authorizedCallers[callerAddress] = false;
        return authorizedCallers[callerAddress];
    }


    //get caller authrozed status


    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */  

    enum AirlineState {
        Applied,
        Registered,
        Paid
    }

    struct Airline {
        address airlineAddress;
        AirlineState state;
        string name;
        mapping(address => bool) airlineAuthorized;
        uint8 airlineAuthorizedCount;
    }



    function getAirlineState(address airline) external view isAuthorized returns (AirlineState) {
        return airlines[airline].state;
    }


    function registerAirline(address airlineAddress, uint8 state, string name) external isAuthorized {
        airlines[airlineAddress] = Airline(airlineAddress, AirlineState(state), name, 0);
    }  

    function changeAirlineState(address airlineAddress, uint8 state) external isAuthorized {
        airlines[airlineAddress].state = AirlineState(state);
        if (state == 2) {
            totalPaidAirlines++;
        }
    } 

    function getTotalPaidAirlines() external view isAuthorized returns (uint256) {
        return totalPaidAirlines;
    }

    function authorizeAirlineRegistration(address airlineAddress, address authorized) external isAuthorized returns (uint8) { 
        require(!airlines[airlineAddress].airlineAuthorized[authorized], "Caller has already been authorized");
        airlines[airlineAddress].airlineAuthorized[authorized] = true;
        airlines[airlineAddress].airlineAuthorizedCount++;
        return airlines[airlineAddress].airlineAuthorizedCount;
    }

    // function isAirlineRegistered (address airlineAddress) external view returns (bool) {
    //     return airlines[airlineAddress].registered;
    // }

    // function registerFlight(address airline, uint256 timestamp, string calldata flight) external requireContractOwner {
    //     _registerflight(airline);
    // }

    // function _registerFlight(address airline, uint256 timestamp, string memory flight ) internal {
    //     bytes32 flightkey = getFlightKey(airline, flight, timestamp);
    //     require(!flights[flightkey].isRegistered, "Flight has already been registered");
    //     require(flights[flightkey].statuscode == 0, "Flight has already taken off");

    //     // create new flight

    //     flights[flightkey] = Flight({
    //         airline: airline,
    //         isRegistered: true,
    //         timestamp: timestamp,
    //         flight: flight,
    //         statuscode: STATUS_CODE_UNKNOWN,
    //         buyeraddress: new address[](0),
    //         credits: 0 ether
            
    //     });


    //     flightKeys.push(flightkey);

    //     emit FlightAdded(flightkey, airline, flight);
    // }


   /**
    * @dev Buy insurance for a flight
    *
    */   

    // insurance event state 


    // get insurance 
    function getInsurance(address passenger, string flight) external view isAuthorized returns (uint256 amount, uint256 payoutAmount, InsuranceState state) {
        amount = passengerInsurances[passenger][flight].amount;
        payoutAmount = passengerInsurances[passenger][flight].payoutAmount;
        state = passengerInsurances[passenger][flight].state;
    }
    // create insurance

    function createInsurance(address passenger, string flight, uint256 amount, uint256 payoutAmount) external view isAuthorized {
        require(passengerInsurances[passenger][flight].amount != amount, "Insurance already exists");
        passengerInsurances[passenger][flight] = Insurance(flight, amount, payoutAmount, InsuranceState.Bought);
    }
    // claim insurance

    function claimInsurance(address passenger, string flight, uint256 amount, uint256 payoutAmount) external view isAuthorized {
        require(passengerInsurances[passenger][flight].state == InsuranceState.Bought, "Insurance has already been bought");
        passengerInsurances[passenger][flight] = Insurance(flight, amount, payoutAmount, InsuranceState.Claimed);
        passengerBalances[passenger] = passengerBalances[passenger] + passengerInsurances[passenger][flight].payoutAmount;
    }
    // get passenger insurance balance

    function getInsuranceBalance(address passenger) external view isAuthorized returns (uint256) {
        return passengerBalances[passenger];
    }
    // pay passenger

    function pay (address passenger) external view  isAuthorized {
        require(passengerBalances[passenger] > 0, "Insuffiencet balance");
        passengerBalances[passenger] = 0;
        passenger.transfer(passengerBalances[passenger]);
    }
    //  



    function buy (address airline, string flight, uint256 timestamp) external requireContractOwner {
        bytes32 flightkey = getFlightKey(airline, flight, timestamp);
        require(!flights[flightkey].isRegistered, "Flight has already been registered");
        require(flights[flightkey].statuscode == 0, "Flight has already taken off");



    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees () external pure {

    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay () external pure {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund () public payable {
    }

    function getFlightKey(address airline, string memory flight,uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
        fund();
    }


}

