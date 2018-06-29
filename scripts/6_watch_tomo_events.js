const Web3 = require('web3');
const contract = require('truffle-contract');
const HDWalletProvider = require("truffle-hdwallet-provider-privkey");

const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const dbPath = path.resolve(__dirname, '../db/tomo.db');

let midasTokenAddressOwner = 'Disclosed';
let privKeys = 'Disclosed';

let midasTokenAddress = 'Disclosed';

let web3wss = new Web3('wss://mainnet.infura.io/ws');
let web3http = new Web3(new HDWalletProvider(privKeys, 'https://mainnet.infura.io/Y0u4pBxqQiOlBjsvNi0L'));

let midasArtifacts = require('../abi/MidasToken.json');
let MidasToken = contract(midasArtifacts);
let MidasTokenContract = new web3http.eth.Contract(MidasToken.abi, midasTokenAddress);

let tomoReceivedAddress = 'Disclosed';
let tomoCoinAddress = 'Disclosed';
let tomoArtifacts = require('../abi/tomo.json');
let TomoCoin = contract(tomoArtifacts);
let tomoContract = new web3wss.eth.Contract(TomoCoin.abi, tomoCoinAddress);


let lastestBlock = 3092417;
let txCalls = {};

function init() {
    const db = new sqlite3.Database(dbPath);
    db.all(`SELECT * FROM tomo`, [], function (err, data) {
	if (err) {
	    return console.log(err.message);
	}
	// get the last insert id
	for (let i = 0; i < data.length; i++) {
	    txCalls[data[i].txId] = data[i].value;
	}
    });
    db.close();
}

function startListening(listenAddress) {
    try {
	console.log("Starting listener ....");
	tomoContract.events.Transfer({}, function (error, result) {
	    console.log('get in here', result);
	    if (result !== undefined && result !== null) {
		let args = result.returnValues;
		if (args["to"].toLowerCase() === listenAddress.toLowerCase()) {
		    args["_txn"] = result.transactionHash;
		    lastestBlock = result.blockNumber;
		    console.log(args);
		    {
			if (!txCalls[args["_txn"]]) {
			    txCalls[args["_txn"]] = args["value"];
			    const db = new sqlite3.Database(dbPath);
			    db.run(`INSERT INTO tomo(txId, address, value, block) VALUES(?, ?, ?, ?)`, [args["_txn"], args["from"], args["value"], result.blockNumber], function (err) {
				if (err) {
				    return console.log(err.message);
				}
				// get the last insert id
				console.log(`A row has been inserted with rowid ${this.lastID}`);
			    });
			    db.close();
			    let c = callMidasContract(args["from"], args["value"]);
			}
		    }
		}
	    }
	}).on('changed', function (event) {
	    console.log('event', event);
	}).on('error', function (error) {
	    console.log('error', error);
	});
    } catch (error) {
	console.log('exception', error);
    }
}

function callMidasContract(from, value) {
    console.log('call midas contract for tomo', from, value);
    if (value > 0) {
	MidasTokenContract.methods.buyByTomo(from, value)
	    .send({from: midasOwnerTokenAddress, gasPrice: web3http.utils.toWei('100', 'gwei'), gas: 7000000})
	    .then(function (result) {
		console.log('result', result);
	    })
	    .catch(function (error) {
		console.log('error', error);
	    })
    } else {
	console.log('Invalid value');
    }
}

startListening('Disclosed');
