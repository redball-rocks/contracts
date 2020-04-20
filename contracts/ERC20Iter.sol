pragma solidity 0.5.8;

//**************************************************
// ERC20 with the ability to iterate over addresses
//**************************************************

import "./ERC20MintBurn.sol";

contract ERC20Iter is ERC20MintBurn {

  address[] private iterAddresses;
  mapping(address => uint256) private reverseIterAddresses;


  // public
 
  function getNumberOfAddresses() public view returns (uint256) {
    return iterAddresses.length;
  }

  function getAddressAt(uint256 idx) public view returns (address) {
    return iterAddresses[idx];
  }


  // private

  function exists(address a) private view returns (bool) {
    if ( iterAddresses.length == 0 ) {
      return false;
    }
    return ( iterAddresses[reverseIterAddresses[a]] == a );
  }

  function addAddress(address a) private {
    if (exists(a)) revert();
    uint256 newLength = iterAddresses.push(a);
    reverseIterAddresses[a] = newLength-1;
  }
  
  function removeAddress(address r) private {
    if (!exists(r)) revert();
    uint idx = reverseIterAddresses[r];
    address last = iterAddresses[iterAddresses.length-1];
    iterAddresses[idx] = last;
    reverseIterAddresses[last] = idx;
    iterAddresses.length--; 
  }


  // override

  function transfer(address recipient, uint256 amount) public returns (bool) {

    require( amount > 0, "zero transfer" );
    
    if ( balanceOf(recipient)==0 ) {
      addAddress(recipient);
    }

    super.transfer(recipient, amount);

    if ( balanceOf(msg.sender)==0 ) {
      removeAddress(msg.sender);
    }

    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    
    require( amount > 0, "zero transfer" );
    
    if ( balanceOf(recipient)==0 ) {
      addAddress(recipient);
    }

    super.transferFrom(sender, recipient, amount);

    if ( balanceOf(sender)==0 ) {
      removeAddress(sender);
    }

    return true;
  }

  function mint(address account, uint256 amount) public returns (bool) {
    
    if ( balanceOf(account) == 0 ) {
      addAddress(account);
    }
    
    super.mint(account, amount);

    return true;
  }

  function burn( uint256 value) public {

    super.burn(value);

    if ( balanceOf(msg.sender) == 0 ) {
      removeAddress(msg.sender);
    }

  }

  function burnFrom(address account, uint256 amount) public {
    
    super.burnFrom(account, amount);

    if ( balanceOf(account) == 0 ) {
      removeAddress(account);
    }
  }

}
