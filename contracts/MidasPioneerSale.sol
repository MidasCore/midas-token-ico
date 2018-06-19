pragma solidity ^0.4.23;
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract MidasPioneerSale is Ownable {
    mapping(address=>uint) public addressCap;

    constructor() public  {}

    event ListAddress( address _user, uint _amount, uint _time );

    // Owner can delist by setting amount = 0.
    // Onwer can also change it at any time
    function listAddress( address _user, uint _amount ) public onlyOwner {
        require(_user != address(0x0));

        addressCap[_user] = _amount;
        emit ListAddress( _user, _amount, now );
    }

    // an optimization in case of network congestion
    function listAddresses( address[] _users, uint[] _amount ) public onlyOwner {
        require(_users.length == _amount.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _amount[i] );
        }
    }

    function getCap( address _user ) public constant returns(uint) {
        return addressCap[_user];
    }
}
