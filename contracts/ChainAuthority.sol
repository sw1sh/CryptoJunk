pragma solidity ^0.4.23;

/*
  The ChainAuthority is the governing contract for CryptoJunk DAO. It holds two important pieces of data--
  the JunkCSR, which is the crypto-spatial registry contract for all Junk Producers, and the user membership
  list, which keeps track of all of the registered users of the DAO. It has the sole authority to extend these
  two registries.
*/

import "./zeppelin-solidity/contracts/ownership/Ownable.sol";

import "./Producer.sol";
import "./FoamCSR.sol";
import "./User.sol";

contract ChainAuthority is Ownable {

    FoamCSR public chainCSR;
    mapping(address => bool) public producers;
    mapping(address => bool) public users;
    mapping(uint256 => address) public junk;

    event RegisteredProducer(address owner, address anchor, bytes8 geohash, bytes32 anchorId);
    event RegisterUser(address owner, address user);

    // Decide whether or not to give the user access to the zone. Mocked for now.
    modifier shouldGiveAccess(bytes4 _zone) {
        _;
    }

    modifier callerIsUser() {
        require(users[msg.sender]);
        _;
    }

    // Deploy a new chain authority.
    constructor(FoamCSR foamCSR) public Ownable() {
        chainCSR = foamCSR;
    }

    // A function to verify a Producer, currently mocked.
    function validateProducer(bytes8 /* _geohash */, bytes32 /* _producerId */) internal pure returns(bool) {
        return true;
    }

    // Deploy a Producer at the given geohash with the given producerId. Transfer ownership of the
    // anchor to the sender of the transaction.
    function registerProducer(bytes8 _geohash, bytes32 _producerId) public {
        require(validateProducer(_geohash, _producerId));
        Producer producer = new Producer(_geohash, _producerId);
        chainCSR.register(producer);
        producers[address(producer)] = true;
        emit RegisteredProducer(msg.sender, address(producer), _geohash, _producerId);
        producer.transferOwnership(msg.sender);
    }

    function validateUser(bytes8 /* _geohash */, address /* _user */) internal pure returns(bool) {
        return true;
    }

    // Create a new user and transer ownership of the account to the message sender.
    function registerUser(bytes8 _geohash) public {
        require(validateUser(_geohash, msg.sender));
        User newUser = new User(_geohash);
        newUser.transferOwnership(msg.sender);
        users[address(newUser)] = true;
        emit RegisterUser(msg.sender, address(newUser));
    }

    // This function is called by a user when they want to add a zone to their list of reached zones.
    function addZone(bytes8 _geohash, bytes4 _zone) public shouldGiveAccess(_zone) callerIsUser() {
        require(validateUser(_geohash, msg.sender));
        require(bytes4(_geohash) == _zone);
        User user = User(msg.sender);
        user.addZone(_zone);
    }

}
