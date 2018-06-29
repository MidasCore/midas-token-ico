pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract MidasToken is StandardToken, Pausable {
    string public constant name = 'MidasProtocol';
    string public constant symbol = 'MAS';
    uint256 public constant minTomoContribution = 100 ether;
    uint256 public constant minEthContribution = 0.1 ether;
    uint256 public constant maxEthContribution = 500 ether;
    uint256 public constant ethConvertRate = 10000; // 1 ETH = 10000 MAS
    uint256 public constant tomoConvertRate = 10; // 1 TOMO = 10 MAS
    uint256 public totalTokenSold = 0;
    uint256 public maxCap = maxEthContribution.mul(ethConvertRate); // Max MAS can buy

    uint256 public constant decimals = 18;
    address public tokenSaleAddress;
    address public midasDepositAddress;
    address public ethFundDepositAddress;
    address public midasFounderAddress;
    address public midasAdvisorOperateMarketingAddress;

    uint256 public fundingStartTime;
    uint256 public fundingEndTime;

    uint256 public constant midasDeposit = 500000000 * 10 ** decimals; // 500.000.000 tokens
    uint256 public constant tokenCreationCap = 5000000 * 10 ** 18; // 5.000.000 token for sale

    mapping(address => bool) public frozenAccount;
    mapping(address => uint256) public participated;

    mapping(address => uint256) public whitelist;
    bool public isFinalized;
    bool public isTransferable;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    event BuyByEth(address from, address to, uint256 val);
    event BuyByTomo(address from, address to, uint256 val);
    event ListAddress(address _user, uint256 cap, uint256 _time);
    event RefundMidas(address to, uint256 val);

    //============== MIDAS TOKEN ===================//

    constructor (address _midasDepositAddress, address _ethFundDepositAddress, address _midasFounderAddress, address _midasAdvisorOperateMarketingAddress, uint256 _fundingStartTime, uint256 _fundingEndTime) public {
        midasDepositAddress = _midasDepositAddress;
        ethFundDepositAddress = _ethFundDepositAddress;
        midasFounderAddress = _midasFounderAddress;
        midasAdvisorOperateMarketingAddress = _midasAdvisorOperateMarketingAddress;

        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;

        balances[midasDepositAddress] = midasDeposit;
        emit Transfer(0x0, midasDepositAddress, midasDeposit);
        totalSupply_ = midasDeposit;
        isFinalized = false;
        isTransferable = true;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(isTransferable == true || msg.sender == midasAdvisorOperateMarketingAddress || msg.sender == midasDepositAddress);
        return super.transfer(_to, _value);
    }

    function setTransferStatus(bool status) public onlyOwner {
        isTransferable = status;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        return super.approve(_spender, _value);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

    function freezeAccounts(address[] _targets, bool _freeze) onlyOwner public {
        for (uint i = 0; i < _targets.length; i++) {
            freezeAccount(_targets[i], _freeze);
        }
    }

    //============== MIDAS PIONEER SALE ===================//

    //============== MIDAS WHITELIST ===================//

    function listAddress(address _user, uint256 cap) public onlyOwner {
        whitelist[_user] = cap;
        emit ListAddress(_user, cap, now);
    }

    function listAddresses(address[] _users, uint256[] _caps) public onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            listAddress(_users[i], _caps[i]);
        }
    }

    function getCap(address _user) public view returns (uint) {
        return whitelist[_user];
    }

    //============== MIDAS PUBLIC SALE =================//

    function() public payable {
        buyByEth(msg.sender, msg.value);
    }

    function buyByEth(address _recipient, uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(now >= fundingStartTime);
        require(now <= fundingEndTime);
        require(_value >= minEthContribution);
        require(_value <= maxEthContribution);
        require(!isFinalized);
        require(totalTokenSold < tokenCreationCap);

        uint256 tokens = _value.mul(ethConvertRate);

        uint256 cap = getCap(_recipient);
        require(cap > 0);

        uint256 tokensToAllocate = 0;
        uint256 tokensToRefund = 0;
        uint256 etherToRefund = 0;

        tokensToAllocate = maxCap.sub(participated[_recipient]);

        // calculate refund if over max cap or individual cap
        if (tokens > tokensToAllocate) {
            tokensToRefund = tokens.sub(tokensToAllocate);
            etherToRefund = tokensToRefund.div(ethConvertRate);
        } else {
            // user can buy amount they want
            tokensToAllocate = tokens;
        }

        uint256 checkedTokenSold = totalTokenSold.add(tokensToAllocate);

        // if reaches hard cap
        if (tokenCreationCap < checkedTokenSold) {
            tokensToAllocate = tokenCreationCap.sub(totalTokenSold);
            tokensToRefund = tokens.sub(tokensToAllocate);
            etherToRefund = tokensToRefund.div(ethConvertRate);
            totalTokenSold = tokenCreationCap;
        } else {
            totalTokenSold = checkedTokenSold;
        }

        // save to participated data
        participated[_recipient] = participated[_recipient].add(tokensToAllocate);

        // allocate tokens
        balances[midasDepositAddress] = balances[midasDepositAddress].sub(tokensToAllocate);
        balances[_recipient] = balances[_recipient].add(tokensToAllocate);

        // refund ether
        if (etherToRefund > 0) {
            // refund in case user buy over hard cap, individual cap
            emit RefundMidas(msg.sender, etherToRefund);
            msg.sender.transfer(etherToRefund);
        }
        ethFundDepositAddress.transfer(address(this).balance);
        //        // lock this account balance
        emit BuyByEth(midasDepositAddress, _recipient, _value);
        return true;
    }

    function buyByTomo(address _recipient, uint256 _value) public onlyOwner returns (bool success) {
        require(_value > 0);
        require(now >= fundingStartTime);
        require(now <= fundingEndTime);
        require(_value >= minTomoContribution);
        require(!isFinalized);
        require(totalTokenSold < tokenCreationCap);

        uint256 tokens = _value.mul(tomoConvertRate);

        uint256 cap = getCap(_recipient);
        require(cap > 0);

        uint256 tokensToAllocate = 0;
        uint256 tokensToRefund = 0;
        tokensToAllocate = maxCap;
        // calculate refund if over max cap or individual cap
        if (tokens > tokensToAllocate) {
            tokensToRefund = tokens.sub(tokensToAllocate);
        } else {
            // user can buy amount they want
            tokensToAllocate = tokens;
        }

        uint256 checkedTokenSold = totalTokenSold.add(tokensToAllocate);

        // if reaches hard cap
        if (tokenCreationCap < checkedTokenSold) {
            tokensToAllocate = tokenCreationCap.sub(totalTokenSold);
            totalTokenSold = tokenCreationCap;
        } else {
            totalTokenSold = checkedTokenSold;
        }

        // allocate tokens
        balances[midasDepositAddress] = balances[midasDepositAddress].sub(tokensToAllocate);
        balances[_recipient] = balances[_recipient].add(tokensToAllocate);

        emit BuyByTomo(midasDepositAddress, _recipient, _value);
        return true;
    }

    /// @dev Ends the funding period and sends the ETH home
    function finalize() external onlyOwner {
        require(!isFinalized);
        // move to operational
        isFinalized = true;
        ethFundDepositAddress.transfer(address(this).balance);
    }
}