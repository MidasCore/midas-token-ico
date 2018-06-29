const MidasToken = artifacts.require("./MidasToken.sol");

module.exports = function (deployer) {
    let ownerContractWallet = 'Disclosed';
    let midasFounderWallet = 'Disclosed';
    let receivedEthWallet = midasFounderWallet;
    let midasAdvisorOperateMarketingWallet = 'Disclosed';
    let midasPioneerSaleWallet = 'Disclosed';

    let founderAmount = 125000000 * 1e18; // 125 million MAS
    let advisorOperateMarketingAmount = 125000000 * 1e18; // 125 million MAS
    let pioneerSaleAmount = 245000000 * 1e18; // 245 million MAS - will be stored in owner wallet
    let publicSaleAmount = 5000000 * 1e18; // 5 million MAS - will be stored in owner wallet
    let totalSupply = founderAmount + advisorOperateMarketingAmount + pioneerSaleAmount + publicSaleAmount; // 500 million MAS

    let publicSaleStartTime = 1530374400;                           // 00:00:00 01/07/2018 GMT+8
    let publicSaleEndTime = publicSaleStartTime + 14 * 3600 * 24;   // 00:00:00 15/07/2018 GMT+8

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
	ownerContractWallet,
    receivedEthWallet, // _ethFundDepositAddress
	midasFounderWallet, // _midasFounderAddress
	midasAdvisorOperateMarketingWallet, // _midasAdvisorOperateMarketingAddress
	publicSaleStartTime,
	publicSaleEndTime
    ).then(function (instance) {
	console.log('tranfer to midas founder wallet');
	tokenInstance = instance;
	return tokenInstance.transfer(midasFounderWallet, founderAmount); // 125,000,000
    }).then(function (txData) {
	console.log('tranfer to advisor wallet');
	return tokenInstance.transfer(midasAdvisorOperateMarketingWallet, advisorOperateMarketingAmount); // 125,000,000
    }).then(function (address) {
	tokenInstance.setTransferStatus(false);
	console.log('Midas Token Address: ', tokenInstance.address);
    }).catch(function (err) {
	console.log('err', err);
    });
};