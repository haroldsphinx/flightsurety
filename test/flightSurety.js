
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
const truffleAssert = require('truffle-assertions');


contract('Flight Surety Tests', async (accounts) => {

    console.log("Accounts", accounts)


  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

//   it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
//     // ARRANGE
//     let newAirline = accounts[2];

//     // ACT
//     try {
//         await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
//     }
//     catch(e) {

//     }
//     let result = await config.flightSuretyData.isAirline.call(newAirline); 

//     // ASSERT
//     assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

//   });

    it('FlightSuretyApp is authorized to make calls to FlightSuretyData', async function () {
        const status = await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
        await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
    });

    it('Contract Owner is created as first airline', async function () {
        assert.equal(await config.flightSuretyData.getAirlineState(accounts[0]), 2, "First Airline");
    })

    it('Airlines can request to be registered', async function () {
        const rar = await config.flightSuretyApp.requestAirlineRegistration('Second Airline', {from: accounts[1]});
        await config.flightSuretyApp.requestAirlineRegistration('Third Airline', {from: accounts[2]});
        await config.flightSuretyApp.requestAirlineRegistration('Fourth Airline', {from: accounts[3]});
        await config.flightSuretyApp.requestAirlineRegistration('Fifth Airline', {from: accounts[4]});

        assert.equal(await config.flightSuretyData.getAirlineState(accounts[1]), 0, "Second Airline Application Received");
        assert.equal(await config.flightSuretyData.getAirlineState(accounts[2]), 0, "Third Airline Application Received");
        assert.equal(await config.flightSuretyData.getAirlineState(accounts[3]), 0, "Fourth Airline Application Received");
        assert.equal(await config.flightSuretyData.getAirlineState(accounts[4]), 0, "Fifth Airline Application Received");

        truffleAssert.eventEmitted(rar, 'AirlineRegistrationRequested', (ev) => {
            return ev.airline === account[1];
        });



    })

    it('Paid airline can approve up to 4 applied airlines', async function () {
        const requestAirlineRegistration = await config.flightSuretyApp.requestAirlineRegistration(accounts[1], { from: accounts[0] });
        await config.flightSuretyApp.requestAirlineRegistration(accounts[2], { from: accounts[1] });
        await config.flightSuretyApp.requestAirlineRegistration(accounts[3], { from: accounts[1] });
    
        const registeredState = 1;
    
        assert.equal(await config.flightSuretyData.getAirlineState(accounts[1]), registeredState, "2nd registered airline is of incorrect state");
        assert.equal(await config.flightSuretyData.getAirlineState(accounts[2]), registeredState, "3rd registered airline is of incorrect state");
        assert.equal(await config.flightSuretyData.getAirlineState(accounts[3]), registeredState, "4th registered airline is of incorrect state");
    
        truffleAssert.eventEmitted(requestAirlineRegistration, 'AirlineRegistrationRequested', (ev) => {
            return ev.airline === accounts[1];
        });
    });

 

});
