pragma solidity ^0.5.0;

import "./openzeppelin-solidity/contracts/access/Roles.sol";

contract PTRole {
  using Roles for Roles.Role;

  event PTAdded(address indexed account);
  event PTRemoved(address indexed account);

  Roles.Role private _pts;

  address private ptAdmin;

  constructor () internal {
    ptAdmin = msg.sender; 
  }

  modifier onlyPT() {
    require(isPT(msg.sender), "PTRole: caller does not have the PT role");
    _;
  }

  function isPT(address account) public view returns (bool) {
    return _pts.has(account);
  }

  function addPT(address account) public {
    require(msg.sender==ptAdmin);
    _pts.add(account);
    emit PTAdded(account);
  }

  function removePT(address account) public {
    require(msg.sender==ptAdmin);
    _pts.remove(account);
    emit PTRemoved(account);
  }
}
