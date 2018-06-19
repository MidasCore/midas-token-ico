const MidasPublicSale = artifacts.require("./MidasPublicSale.sol");
const WhiteListContract = artifacts.require("./MidasWhiteList.sol");
const MidasPioneerSale = artifacts.require("./MidasPioneerSale.sol");
const MidasToken = artifacts.require("./MidasToken.sol");

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

const Promise = require('bluebird');

module.exports = function (deployer) {
    let ownerContractWallet = "0x0d4273114b85e60cbc50b72c45471d974bb7c63c"; // Ganache owner 1
    // let ownerContractWallet = "0xcF916e6A5d570F239143B4EF1f0215Ed905c2114"; // Ganache owner 2

    let midasFounderWallet = '0x025834d9dcaf3b159c9d4bac746dad6feb07b6a9';
    let midasAdvisorOperateMarketingWallet = "0xcb7efb35ba2f873ef9034942f1585e5eab9f93f6";
    let midasPioneerSaleWallet = "0x552282dd91c8e588d606f5747b569ed037f11c7f";
    let midasPublicSaleWallet = "0x0b21a72a42710b48b8ff1fb4adffa6de9e9698d6";

    let founderAmount = 125000000 * 1e18; // 125 million MAS
    let advisorOperateMarketingAmount = 125000000 * 1e18; // 125 million MAS
    let pioneerSaleAmount = 245000000 * 1e18; // 245 million MAS
    let publicSaleAmount = 5000000 * 1e18; // 5 million MAS
    let totalSupply = founderAmount + advisorOperateMarketingAmount + pioneerSaleAmount + publicSaleAmount; // 500 million MAS

    let publicSaleStartTime = 1530374400; // 00:00:00 01/07/2018 GMT+8
    let publicSaleEndTime = publicSaleStartTime + 14 * 3600 * 24; // 00:00:00 15/07/2018 GMT+8

    // uncomment below to open the sale immediately (testing only)
    // publicSaleStartTime = (Date.now() / 1000 | 0) + 60;

    console.log('================================');
    console.log('totalSupply                   = ', totalSupply);
    console.log('founderAmount                 = ', founderAmount);
    console.log('advisorOperateMarketingAmount = ', advisorOperateMarketingAmount);
    console.log('pioneerSaleAmount             = ', pioneerSaleAmount);
    console.log('publicSaleAmount              = ', publicSaleAmount);
    console.log('================================');
    console.log('publicSaleStartTime = ', new Date(publicSaleStartTime * 1000).toString());
    console.log('publicSaleEndTime   = ', new Date(publicSaleEndTime * 1000).toString());
    console.log('================================');

    let tokenInstance, whiteListInstance, publicSaleInstance;

    deployer.deploy(
        MidasToken,
        publicSaleStartTime,
        publicSaleEndTime,
        ownerContractWallet,
        midasFounderWallet,
        midasAdvisorOperateMarketingWallet,
        midasPioneerSaleWallet,
        midasPublicSaleWallet
    ).then(function (instance) {
        tokenInstance = instance;
        return tokenInstance.transfer(midasFounderWallet, founderAmount); // 125,000,000
    }).then(function (txData) {
        return tokenInstance.transfer(midasAdvisorOperateMarketingWallet, advisorOperateMarketingAmount); // 125,000,000
    }).then(function (txData) {
        return tokenInstance.transfer(midasPioneerSaleWallet, pioneerSaleAmount); // 245,000,000
    }).then(function (txData) {
        return tokenInstance.transfer(midasPublicSaleWallet, publicSaleAmount);
    }).then(function (txData) {
        return deployer.deploy(WhiteListContract)
    }).then(function (instance) {
        whiteListInstance = instance;
        return deployer.deploy(
            MidasPublicSale,
            ownerContractWallet,
            ownerContractWallet,
            whiteListInstance.address,
            publicSaleStartTime,
            publicSaleEndTime,
            tokenInstance.address);
    }).then(function (instance) {
        publicSaleInstance = instance;
        return tokenInstance.setTokenSaleContract(publicSaleInstance.address);
    }).then(function () {
        console.log('Midas Token Address: ', tokenInstance.address);
        console.log('Whitelist Contract Address: ', whiteListInstance.address);
        console.log('Midas Public Sale Address: ', publicSaleInstance.address);
    }).catch(function (err) {
        console.log('err', err);
    });
};