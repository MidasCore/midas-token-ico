const fs = require('fs');
const parse = require('csv-parse');

let csvData = [];
let i = 0;
let addresses = [];
let amounts = [];

let PioneerSaleContract = artifacts.require("./MidasPioneerSale.sol");
const PIONEER_SALE_CONTRACT_ADDRESS = 'Disclosed';

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

module.exports = function (deployer) {
    fs.createReadStream('./data/pioneer_sale.csv').pipe(parse({delimiter: ','})).on('data', function (csvrow) {
	//do something with csvrow
	console.log(i);

	if (i > 0) {
	    addresses.push(csvrow[1]);
	    amounts.push(web3.toWei(csvrow[3], 'ether'));
	    if (i % 20 === 0) {
		csvData.push({'addresses': addresses, 'amounts': amounts});
		addresses = [];
		amounts = [];
	    }
	}
	i = i + 1;
	// i++;

    }).on('end', function () {
	if (addresses.length > 0)
	    csvData.push({'addresses': addresses, 'amounts': amounts});
	for (let i = 0; i < csvData.length; i++) {
	    PioneerSaleContract.at(PIONEER_SALE_CONTRACT_ADDRESS).listAddresses(csvData[i].addresses, csvData[i].amounts);
	    console.log(csvData[i].addresses);
	}
    });
};
