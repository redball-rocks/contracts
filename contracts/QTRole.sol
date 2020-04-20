pragma solidity ^0.5.0;

import "./openzeppelin-solidity/contracts/access/Roles.sol";

contract QTRole {
  using Roles for Roles.Role;

  event QTAdded(address indexed account);
  event QTRemoved(address indexed account);

  Roles.Role private _qts;

  address private qtAdmin;

  constructor () internal {
    qtAdmin = msg.sender; 
  }

  modifier onlyQT() {
    require(isQT(msg.sender), "QTRole: caller does not have the QT role");
    _;
  }

  function isQT(address account) public view returns (bool) {
    return _qts.has(account);
  }

  function addQT(address account) public {
    require(msg.sender==qtAdmin);
    _qts.add(account);
    emit QTAdded(account);
  }

  function removeQT(address account) public {
    require(msg.sender==qtAdmin);
    _qts.remove(account);
    emit QTRemoved(account);
  }
}
