pragma solidity 0.5.8;

//***************************************************
// ERC20 with the ability to set balance granularity
//***************************************************

import "./ERC20MintBurn.sol";

contract ERC20Granular is ERC20MintBurn {

  uint256 public granularity;

  // e.g. 10**18

  constructor(uint256 g) public {
    granularity = g;
  } 

  // private

  function isMultiple(uint256 n) private view returns(bool) {
    return(n.div(granularity).mul(granularity) == n);
  }
  
  function checkGranular(uint256 n) internal view {
    require(isMultiple(n), "Granularity breached");
  }


  // override ERC20s

  function transfer(address recipient, uint256 amount) public returns (bool) {
    checkGranular(amount);
    return super.transfer(recipient, amount);
  }
  
  function approve(address spender, uint256 value) public returns (bool) {
    checkGranular(value);
    return super.approve(spender, value);
  }
  
  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    checkGranular(amount);
    return super.transferFrom(sender, recipient, amount);
  }
  
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    checkGranular(addedValue);
    return super.increaseAllowance(spender, addedValue);
  }
  
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    checkGranular(subtractedValue);
    return super.decreaseAllowance(spender, subtractedValue);
  }

  function mint(address account, uint256 amount) public returns (bool) {
    checkGranular(amount);
    return super.mint(account, amount);
  }
  
  function burn(uint256 amount) public {
    checkGranular(amount);
    super.burn(amount);
  }

  function burnFrom(address account, uint256 amount) public {
    checkGranular(amount);
    super.burnFrom(account, amount);
  }

}
