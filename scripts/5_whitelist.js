const fs = require('fs');
const parse = require('csv-parse');
const sleep = require('sleep');

let csvData = [];

let MidasTokenContract = artifacts.require("./MidasToken.sol");
const MIDAS_TOKEN_CONTRACT_ADDRESS = 'Disclosed';

// Copy & Paste this
Date.prototype.getUnixTime = function () {
    return this.getTime() / 1000 | 0
};
if (!Date.now) Date.now = function () {
    return new Date();
};
Date.time = function () {
    return Date.now().getUnixTime();
};

//TODO : set frozen fun

module.exports = function (deployer) {
    fs.createReadStream('./data/pioneer_sale.csv').pipe(parse({delimiter: ','})).on('data', function (csvrow) {
	csvData.push(csvrow);

    }).on('end', function () {

	for (let i = 0; i < csvData.length; i++) {
	    if (i > 0) {
		MidasTokenContract.at(MIDAS_TOKEN_CONTRACT_ADDRESS).transferPrivateSale(csvData[i][1], web3.toWei(csvData[i][3], 'ether'));
		console.log(csvData[i][1]);
	    }

	    if (i % 10 === 0) {
		sleep.sleep(7 * 60);
	    }
	}
    });
};
