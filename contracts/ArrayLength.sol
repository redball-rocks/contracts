pragma solidity 0.5.8;

contract ArrayLength {

  event E(uint256 thislong);

  address[] a;

  function f() public {

    uint256 thislong = a.length;

    emit E(thislong);
  }
}
