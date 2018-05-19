pragma solidity ^0.4.13;

/*
  The Producer represents a physical device that has a fixed location, and can be user to
  validate a users request to pay for parking. It has two pieces of data, an authority and an id,
  which can be used as an external uuid. It is registered to an authority, hence also to
  the authority's spatial registry. In order to interact with a user, the user must be
  located in the zone in which the producer is located.
*/

import "./CSC.sol";
import "./User.sol";
import "./ChainAuthority.sol";

contract Producer is Ownable, CSC {

    bytes32 public producerId;
    ChainAuthority public chainAuthority;

    event RequestJunk(address producer, address user, uint256 tokenId);

    modifier callerIsUser() {
        require(chainAuthority.users(msg.sender));
        _;
    }

    function Producer(bytes8 _geohash, bytes32 _producerId) public CSC(_geohash) Ownable() {
        producerId = _producerId;
        chainAuthority = ChainAuthority(msg.sender);
    }

    // note that beacuse we are looking up the user from the ChainAuthority, we can be sure
    // they exist and we deployed by the authority.
    function requestJunk(uint256 tokenId) public payable callerIsUser() returns(bool) {
        User user = User(msg.sender);
        if (user.activeProducer() == this) {
            RequestJunk(this, address(user), tokenId);
            return true;
        } else {
            revert();
        }
    }

    // transfer all ether accumulated in collection fees to the owner of this contract.
    function transferBalanceToOwner() public onlyOwner() {
        owner.transfer(this.balance);
    }
}
