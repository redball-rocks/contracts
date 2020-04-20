pragma solidity ^0.5.0;

import "./openzeppelin-solidity/contracts/access/Roles.sol";

contract MinterRoleCust {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;

  address private minterAdmin;

  constructor () internal {
    minterAdmin = msg.sender; 
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return _minters.has(account);
  }

  function addMinter(address account) public {
    require(msg.sender==minterAdmin);
    _minters.add(account);
    emit MinterAdded(account);
  }

  function removeMinter(address account) public {
    require(msg.sender==minterAdmin);
    _minters.remove(account);
    emit MinterRemoved(account);
  }
}
