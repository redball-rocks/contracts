pragma solidity 0.5.8;

contract TestIter{

  constructor() public {
    mintTickets(0x0A5F67E5A6F5A48eE6A63cd5355A0DCe0C13587B,10);
  }

  event E(uint256 output);
  event S(string output);

  address[] ticketToOwner;
  mapping( address => uint256[] ) ownerToTickets;

  function mintTickets(address newTicketOwner, uint256 numberToIssue) public {

    uint256 start = ticketToOwner.length;
    uint256 end = start+numberToIssue-1;
    
    for(uint256 i=start; i<=end; i++) {
      ticketToOwner.push(newTicketOwner);
      ownerToTickets[newTicketOwner].push(i); 
    }
  } 
  
  function getTickets(address ticketOwner) public view returns (uint256[] memory) {
      return ownerToTickets[ticketOwner];
  }
  
  function getNumberTickets(address ticketOwner) public view returns (uint256) {
      return ownerToTickets[ticketOwner].length;
  }
 
  function totalTickets() public view returns (uint256) {
      return ticketToOwner.length;
  }
  
  function transferTickets(address oldTicketOwner, address newTicketOwner, uint256 numberToTransfer) public {

    assert( numberToTransfer>0 );
    assert( oldTicketOwner != newTicketOwner );
    assert( ownerToTickets[oldTicketOwner].length >= numberToTransfer );

    uint256 i = ownerToTickets[oldTicketOwner].length;
    uint256 stop = i-numberToTransfer;

    do {

    // 0x0A5F67E5A6F5A48eE6A63cd5355A0DCe0C13587B
    // 0xD034739C2aE807C70Cd703092b946f62a49509D1
    
      emit E(i);
    
      uint256 n = ownerToTickets[oldTicketOwner][i-1];

      ownerToTickets[oldTicketOwner].length--;
      ownerToTickets[newTicketOwner].push(n);
      ticketToOwner[n]=newTicketOwner;

      i--;
      
    } while ( i>stop);
  } 
  
  uint256 x;
  
  function silly() public returns (uint256){
      x=0;
      for(uint256 i=0; i<1000; i++) {
          x=x+i;
      }
      return x;
  }

}  
