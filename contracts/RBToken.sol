pragma solidity 0.5.8;

import "./openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./openzeppelin-solidity/contracts/utils/Address.sol";

// modified version of Zeppelin, only owner can create minters
import "./ERC20MintBurn.sol";

import "./QTRole.sol";
import "./PTRole.sol";
import "./ERC20Iter.sol";
import "./ERC20Granular.sol";


contract RedBallToken is ERC20MintBurn,                     // ERC20 with mint and burn functionality 
                                                            // minting requires minter role

                         QTRole, PTRole,                    // onlyQT, onlyPT modifiers
                         Ownable,                           // onlyOwner modifier
                         Pausable,                          // whenNotPaused, whenPaused modifiers
                         
                         ERC20Iter,                         // iteratable address list
                         ERC20Granular(10**18)              // granularity
                         {
    
  using SafeMath for uint256;

  string public constant name = "Red Ball Loyalty Token";
  string public constant symbol = "RBLT";
  uint8 public constant decimals = 18;
  
  

  // Standard ERC20 stuff...

  function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
    return super.transfer(recipient, amount);
  }
  
  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    return super.approve(spender, value);
  }
  
  function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
    return super.transferFrom(sender, recipient, amount);
  }
  
  function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
    return super.increaseAllowance(spender, addedValue);
  }
  
  function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
    return super.decreaseAllowance(spender, subtractedValue);
  }

  function mint(address account, uint256 amount) public onlyMinter returns (bool) {
    return super.mint(account, amount);
  }
  
  function burn(uint256 amount) public whenNotPaused {
    super.burn(amount);
  }

  function burnFrom(address account, uint256 amount) public whenNotPaused {
    super.burnFrom(account, amount);
  }


  // *******************************************
  // Select and pay a winning address...
  // 
  //  1) queTicket(tN) amt -- pay into contract and select winner:
  //       QT pays amt into the contract, 
  //       passes in tN the "ticket number" of the winner,
  //       get bN = current block number
  //       creates payment entry ( ref => { tN, bN, amt, 0x0 } ) 
  //       emits event: ref, tN, bN, amt
  //
  //  2) Calc winning address:
  //       Off-chain, PT calls ticketToAddress(tN) for block bN
  //  
  //  3) payTicket(ref, pA) -- pay the winner:
  //       PT calls with the ref and winning address,
  //       require: payment[ref].pA==0x0 && amt > this.balance
  //       updates payment entry ( ref => { 0x0 to pA } )
  //       send amt to pA
  //****************************************************************************************

  event QueTicket(bytes32 indexed ref, uint256 ticketNumber, uint256 blockNumber, uint256 amount);
  event PayTicket(bytes32 indexed ref, address payAddress, uint256 amount);
  
  struct Payment {
      uint256 ticketNumber;
      uint256 blockNumber;
      uint256 amount;
      address payAddress;
  }

  mapping( bytes32 => Payment) public payments;

  function queTicket(bytes32 ref, uint256 ticketNumber) public payable onlyQT {
      
    payments[ref] = Payment({ 
                                ticketNumber: ticketNumber,
                                blockNumber: block.number,
                                amount: msg.value,
                                payAddress: address(0)
                    });
                                
    emit QueTicket(ref, ticketNumber, block.number, msg.value);
  }
  
  function ticketToAddress(uint256 ticketNumber) public view returns (address) {
    
    uint256 position=0;
    for(uint256 i=0; i<getNumberOfAddresses(); i++) {
      position += balanceOf(getAddressAt(i));
      if ( position > ticketNumber ) {
        return getAddressAt(i);
      }
    }
    
    // although insanely unlikely, this is possible;
    // consider the case where the ticket number is
    // near or at the top balance, in the same block 
    // after the queTicket call, some holders
    // transfer their tokens ....
    // basically, it is possible the number of holders
    // and therefore the iterAddresses is shorter than
    // it was when the ticket number was generated
    
    return address(0);
  }

  function payTicket(bytes32 ref, address payAddress) public onlyPT {
    require(payments[ref].payAddress==address(0), "Double payment");
    uint256 amount = payments[ref].amount;
    payments[ref].payAddress=payAddress;
    Address.toPayable(payAddress).transfer(amount);
    emit PayTicket(ref, payAddress, amount);
  }
}
