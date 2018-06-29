const HDWalletProvider = require('truffle-hdwallet-provider');
const HDWalletPrikeyProvider = require('truffle-hdwallet-provider-privkey');
const mnemonic = '';

module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*",
            from: 'Disclosed'
        },
        ropsten: {
            provider: function () {
                return new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/x');
            },
            network_id: 3,
            gas: 4000000,
            gas_price: 100,
            from: 'Disclosed'
        },
        main: {
            provider: function () {
                return new HDWalletPrikeyProvider('', 'https://mainnet.infura.io/x');
            },
            network_id: 1,
            gas: 4000000,
            gas_price: 100,
            from: 'Disclosed'
        }
    }
};
