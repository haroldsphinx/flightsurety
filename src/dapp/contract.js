import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';  
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            this.flightSuretyApp.methods.registerFlight(this.web3.utils.fromAscii('FLIGHT1'), Math.floor(Date.now() / 1000 ))
            .send({from: this.owner, gas:650000}, (error, result) => {
                console.log("Flight1 Registered");
            });

            this.flightSuretyApp.methods.registerFlight(this.web3.utils.fromAscii('FLIGHT2'), Math.floor(Date.now() / 1000 ))
            .send({from: this.owner, gas:650000}, (error, result) => {
                console.log("Flight2 Registered");
            });

            this.flightSuretyApp.methods.registerFlight(this.web3.utils.fromAscii('FLIGHT3'), Math.floor(Date.now() / 1000 ))
            .send({from: this.owner, gas:650000}, (error, result) => {
                console.log("Flight3 Registered");
            });

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    purchaseInsurance(airline, flight, timestamp, amount, callback) {
        let self = this;
        self.flightSuretyApp.methods.purchaseInsurance(airline, flight, timestamp)
        .send({from: self.owner, value: self.web3.utils.toWei(amount, "ether"), gas: 500000}, (error, result) => {
            callback(error, payload);
        })
    }

    getFlights(callback) {
        let self = this;
        self.flightSuretyApp.methods.getFlightsCount()
        .call({from: self.owner}, (err, flightsCount) => {
            const flights = [];
            for(var i = 0; i<flightsCount; i++) {
                const result = self.flightSuretyApp.methods.getFLight(i).call({from:self.owner});
                flights.push(result);
            }
        })
        callback(error, flights);

    }

    getBalance(callback) {
        let self = this;
        self.flightSuretyApp.methods.withdrawBalance()
        .send({from:self.owner}, (error, result) => {
            callback(error, result)
        })
    }

    claimInsurance(callback, airline, flight, timestamp) {
        let self = this;
        self.flightSuretyApp.methods.claimInsurance(airline, flight, timestamp)
        .send({from: self.owner}, (error, result) => {
            callback(error, result);
        })
    }

  
}