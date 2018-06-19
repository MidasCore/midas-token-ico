pragma solidity ^0.4.23;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './MidasPioneerSale.sol';

contract MidasToken is StandardToken, Ownable {
    string  public  constant name = "Midas";
    string  public  constant symbol = "MAS";
    uint    public  constant decimals = 18;
    uint    public   totalSupply = 500000000 * 10**decimals; //500,000,000

    uint    public  constant founderAmount = 125000000 * 10**decimals; // 125,000,000
    uint    public  constant advisorOperateMarketingAmount = 125000000 * 10**decimals; // 125,000,000
    uint    public  constant pioneerSaleAmount = 245000000 * 10**decimals; // 245,000,000
    uint    public  constant publicSaleAmount = 5000000 * 10**decimals; // 5,000,000

    address public   midasFounderCoreStaffWallet;
    address public   midasAdvisorOperateMarketingWallet;
    address public   midasPioneerSaleWallet;
    address public   midasPublicSaleWallet;

    uint    public  saleStartTime;
    uint    public  saleEndTime;

    address public  tokenSaleContract;
    MidasPioneerSale public privateSaleList;

    mapping(address => bool) public frozenAccount;
    mapping(address => uint) public frozenTime;
    mapping(address => uint) public maxAllowedAmount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen, uint _seconds);

    function checkMaxAllowed(address target) public constant returns (uint) {
        uint256 maxAmount = balances[target];
        if (target == midasFounderCoreStaffWallet) {
            maxAmount = 125000000 * 1e18;
        }
        if (target == midasAdvisorOperateMarketingWallet) {
            maxAmount = 125000000 * 1e18;
        }
        if (target == midasPioneerSaleWallet) {
            maxAmount = 245000000 * 1e18;
        }
        if (target == midasPublicSaleWallet) {
            maxAmount = 5000000 * 1e18;
        }
        return maxAmount;
    }

    function selfFreeze(bool freeze, uint _seconds) public {
        // selfFreeze cannot more than 7 days
        require(_seconds <= 7 * 24 * 3600);
        // if unfreeze
        if (!freeze) {
            // get End time of frozenAccount
            uint frozenEndTime = frozenTime[msg.sender];
            // if now > frozenEndTime
            require(now >= frozenEndTime);
            // unfreeze account
            frozenAccount[msg.sender] = freeze;
            // set time to 0
            _seconds = 0;
        } else {
            frozenAccount[msg.sender] = freeze;

        }
        // set endTime = now + _seconds to freeze
        frozenTime[msg.sender] = now + _seconds;
        emit FrozenFunds(msg.sender, freeze, _seconds);
    }

    function freezeAccount(address target, bool freeze, uint _seconds) onlyOwner public {
        // if unfreeze
        if (!freeze) {
            // get End time of frozenAccount
            uint frozenEndTime = frozenTime[target];
            // if now > frozenEndTime
            require(now >= frozenEndTime);
            // unfreeze account
            frozenAccount[target] = freeze;
            // set time to 0
            _seconds = 0;
        } else {
            frozenAccount[target] = freeze;

        }
        // set endTime = now + _seconds to freeze
        frozenTime[target] = now + _seconds;
        emit FrozenFunds(target, freeze, _seconds);

    }

    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(!frozenAccount[to]);
        // Check if recipient is frozen
        _;
    }
    modifier validFrom(address from){
        require(!frozenAccount[from]);
        // Check if sender is frozen
        _;
    }
    modifier onlyWhenTransferEnabled() {
        if (now <= saleEndTime && now >= saleStartTime) {
            require(msg.sender == tokenSaleContract);
        }
        _;
    }
    modifier onlyPrivateListEnabled(address _to){
        require(now <= saleStartTime);
        uint allowcap = privateSaleList.getCap(_to);
        require(allowcap > 0);
        _;
    }
    function setPrivateList(MidasPioneerSale _privateSaleList) onlyOwner public {
        require(_privateSaleList != address(0x0));
        privateSaleList = _privateSaleList;

    }

    constructor (
        uint startTime,
        uint endTime,
        address admin,
        address _midasFounderCoreStaffWallet, // founder wallet
        address _midasAdvisorOperateMarketingWallet, // advisor wallet
        address _midasPioneerSaleWallet, // network growth wallet, bonus
        address _midasPublicSaleWallet // public sale wallet
    ) public {
        require(admin != address(0x0));
        require(_midasFounderCoreStaffWallet != address(0x0));
        require(_midasAdvisorOperateMarketingWallet != address(0x0));
        require(_midasPioneerSaleWallet != address(0x0));
        require(_midasPublicSaleWallet != address(0x0));

        // Mint all tokens. Then disable minting forever.
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, totalSupply);
        // init internal amount limit
        // set address when deploy
        midasFounderCoreStaffWallet = _midasFounderCoreStaffWallet;
        midasAdvisorOperateMarketingWallet = _midasAdvisorOperateMarketingWallet;
        midasPioneerSaleWallet = _midasPioneerSaleWallet;
        midasPublicSaleWallet = _midasPublicSaleWallet;

        saleStartTime = startTime;
        saleEndTime = endTime;
        transferOwnership(admin);
    }

    // get addr balance
    function getBalance(address addr)
    public view returns (uint) {
        return balances[addr];
    }

    function setTimeSale(uint startTime, uint endTime) onlyOwner
    public {
        require(now < saleStartTime || now > saleEndTime);
        require(now < startTime);
        require(startTime < endTime);
        saleStartTime = startTime;
        saleEndTime = endTime;
    }

    function setTokenSaleContract(address _tokenSaleContract)
    onlyOwner
    public {
        // check address ! 0
        require(_tokenSaleContract != address(0x0));
        // do not allow run when saleStartTime <= now <= saleEndTime
        require(now < saleStartTime || now > saleEndTime);

        tokenSaleContract = _tokenSaleContract;
    }

    function transfer(address _to, uint _value)
    onlyWhenTransferEnabled validDestination(_to) validFrom(msg.sender)
    public returns (bool) {
        if (msg.sender == midasFounderCoreStaffWallet || msg.sender == midasAdvisorOperateMarketingWallet ||
        msg.sender == midasPioneerSaleWallet || msg.sender == midasPublicSaleWallet) {

            // check maxAllowedAmount
            uint withdrawAmount = maxAllowedAmount[msg.sender];
            uint defaultAllowAmount = checkMaxAllowed(msg.sender);
            uint maxAmount = defaultAllowAmount - withdrawAmount;
            // _value transfer must <= maxAmount
            require(maxAmount >= _value);
            //
            // if maxAmount = 0, need to block this msg.sender
            if (maxAmount == _value) {

                bool isTransfer = super.transfer(_to, _value);
                // freeze account
                selfFreeze(true, 24 * 3600);
                // temp freeze account 24h
                maxAllowedAmount[msg.sender] = 0;
                return isTransfer;
            } else {
                // set max withdrawAmount
                maxAllowedAmount[msg.sender] = maxAllowedAmount[msg.sender].add(_value);
                //

            }
        }
        return super.transfer(_to, _value);

    }

    function transferPrivateSale(address _to, uint _value)
    onlyOwner onlyPrivateListEnabled(_to)
    public returns (bool) {
        return transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
    onlyWhenTransferEnabled validDestination(_to) validFrom(_from)
    public returns (bool) {
        if (_from == midasFounderCoreStaffWallet || _from == midasAdvisorOperateMarketingWallet ||
        _from == midasPioneerSaleWallet || _from == midasPublicSaleWallet) {

            // check maxAllowedAmount
            uint withdrawAmount = maxAllowedAmount[_from];
            uint defaultAllowAmount = checkMaxAllowed(_from);
            uint maxAmount = defaultAllowAmount - withdrawAmount;
            // _value transfer must <= maxAmount
            require(maxAmount >= _value);

            // if maxAmount = 0, need to block this _from
            if (maxAmount == _value) {

                bool isTransfer = super.transfer(_to, _value);
                // freeze account
                selfFreeze(true, 24 * 3600);
                maxAllowedAmount[_from] = 0;
                return isTransfer;
            } else {
                // set max withdrawAmount
                maxAllowedAmount[_from] = maxAllowedAmount[_from].add(_value);

            }
        }
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value)
    onlyWhenTransferEnabled
    public returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value)
    onlyWhenTransferEnabled
    public returns (bool) {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
    }

    function emergencyERC20Drain(ERC20 token, uint amount) onlyOwner public {
        token.transfer(owner, amount);
    }
}
