const HDWalletProvider = require('truffle-hdwallet-provider');
const mnemonic = 'reform obey remember noble main minimum badge uncle evil cheese spoon wasp';
module.exports = {
    networks: {
        development: {
            host: "127.0.0.1",
            port: 7545,
            network_id: "*"
        },
        ropsten: {
            provider: function () {
                return new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/Y0u4pBxqQiOlBjsvNi0L');
            },
            network_id: 3,
            host: "localhost",
            port: 8545,
            gas: 2900000
        }
    }
};
