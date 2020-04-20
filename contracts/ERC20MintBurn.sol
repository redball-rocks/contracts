pragma solidity ^0.5.0;

// ERC20 with Mint and Burn functionality

import "./openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

// Different from Zeppelin, only admin can create minters, not other minters

import "./MinterRoleCust.sol";

contract ERC20MintBurn is ERC20, MinterRoleCust {

    // only minters can mint...
  
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    // anyone can burn their own tokens...

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // or tokens approved to them...

    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

}
