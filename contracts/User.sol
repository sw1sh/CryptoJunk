pragma solidity ^0.4.13;

/*
  A User is the proxy contract for an ethereum account that wants to use the ChainAuthority's
  services. If they sign up through the authority (which is the only way), they will be given
  exclusive ownership over their account.

  They use this account to collect junk in the zones they reached with (not yet implemented) Dynamic Proof-Of-Location.
*/

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

import "./Producer.sol";
import "./ChainAuthority.sol";

contract User is Ownable, CSC {

    ChainAuthority public chainAuthority;
    Producer public activeProducer;
    mapping(bytes4 => bool) public reachableZones;

    event CheckIn(address user, address producer);

    modifier callerIsChainAuthority() {
        ChainAuthority authority = ChainAuthority(msg.sender);
        require(chainAuthority == authority);
        _;
    }

    // make sure the sender of this message is the valid activeProducer.
    modifier callerIsActiveProducer() {
        require(chainAuthority.producers(msg.sender));
        Producer producer = Producer(msg.sender);
        require(producer == activeProducer);
        _;
    }

    // A user is created by a ChainAuthorty.
    function User() public Ownable {
        chainAuthority = ChainAuthority(msg.sender);
    }

    // Set the pending anchor to indicate interest in using a Producer
    function setActiveProducer(Producer _producer) internal onlyOwner() {
        activeProducer = _producer;
    }

    // Activate producer for consequent interaction, assuming the user has access to their zone.
    function activate(Producer _producer) public payable onlyOwner() {
        require(chainAuthority.producer(address(_producer)));
        setActiveProducer(_producer);
        _producer.acceptCollection.value(msg.value)();
    }

    // The chain authority calls this function to modify the set of availableZones.
    function addZone(bytes4 _zone) public callerIsChainAuthority() {
        availableZones[_zone] = true;
        ZoneReached(_zone);
    }

    // the owner of the User contract can request to the ChainAuthority to add
    // a zone to their set of reachableZones.
    function reachZone(bytes4 _zone) public onlyOwner {
        chainAuthority.addZone(_zone);
    }

}
