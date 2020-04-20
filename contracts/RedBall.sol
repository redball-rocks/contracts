pragma solidity 0.5.8;
 
import "./openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./openzeppelin-solidity/contracts/utils/Address.sol";

interface RBT {
    function mint(address beneficiary, uint256 amount ) external;
    function totalSupply() external returns (uint256);
    function queTicket(bytes32 ref, uint256 ticketNumber) external payable;
}  

contract RedBall is Ownable {

    using SafeMath for uint256;

    RBT public rbt;

    // constants 

    uint256[] public validOutcomesList = [ uint256(1), 2, 3, 4, 9 ];

    function getValidOutcomesList() public view returns( uint256[] memory ) {
        return validOutcomesList;
    }
   
    mapping( uint256 => bool ) public validOutcome;

    uint256 public gameMaxBetsPerOutcome = 99;  

    uint256 public maxTicketsPerOutcome = 10;  // don't let them buy more tickets than this on one outcome
    
    uint256 public maxOutcomes = 3;  // don't let them bet on more outcomes than this

    uint256 public ticketPrice = 0.01 ether;

    mapping( uint256 => uint256 ) public amtToTicket;  // Amt of Ether to Number of Tickets 

    uint256 constant STATE_OPEN   = 1;
    uint256 constant STATE_CLOSED = 2;
    uint256 constant STATE_FINAL  = 3;


    // vars

    bytes32 public currentGameId;

    uint256 public closingTimestamp = 0;

    uint256 public currentGameOutcome = 0;


    uint256 private internalGameState = STATE_FINAL;

    function currentGameState() public view returns ( uint256 ) {
      if ( STATE_OPEN == internalGameState && block.timestamp > closingTimestamp ) {
        return STATE_CLOSED;
      } else {
        return internalGameState;
      }
    }    

    uint256 public amtJP = 0;  // jack pot    
    uint256 public amtGP = 0;  // game pot 
    uint256 public amtLP = 0;  // loyalty pot
    uint256 public amtRP = 0;  // reserve pot
    uint256 public fee   = 0;  // our fee    
 

    // player winnings in Eth

    mapping( address => uint256 ) public balanceOf;   

    // bets player has made this game player->outcome->tickets

    mapping( address => mapping( uint256 => uint256 ) ) public betsOf; 

    // total tickets across all players per outcome this game

    mapping( uint256 => uint256 ) public outcomeTotalTickets;  

    // list of players betting on an outcome 

    mapping( uint256 => address[] ) public outcomeBetList;    

    function getOutcomeBetList( uint256 outcome ) public view returns ( address[] memory ) {
        return outcomeBetList[outcome];
    }

    function getOutcomeTicketList( uint256 outcome ) public view returns( uint256[] memory ) {
      uint256[] memory list = new uint256[](gameMaxBetsPerOutcome);
      for( uint256 n=0; n<outcomeBetList[outcome].length; n++ ) {
        address a = outcomeBetList[outcome][n];
        uint256 tickets = betsOf[a][outcome]; 
        list[n] = tickets ;
      }
      return list;
    } 

    //+++++++++++++
    // Constructor
    //+++++++++++++

    constructor() public {

      for( uint256 i=0; i<validOutcomesList.length; i++ ) {
          uint256 v = validOutcomesList[i];
          validOutcome[v]=true;
      }
   
      for( uint256 i=1; i<=maxTicketsPerOutcome; i++ ) {
          amtToTicket[ticketPrice * i] = i ;
      }
   
    }

    function setRBT( address rbtInstance ) public onlyOwner {
      rbt = RBT( rbtInstance );
    }

    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //
    // Game player functions
    //
    // on-chain:
    // 
    //   betNew( gid, outcome ) payable  -- bet on outcome, with eth, event Bet
    //
    //   betStash( gid, outcome, amt )  -- bet on outcome from funds in contract, event Bet
    //
    //   withdraw()  -- withdraw funds from contract, event Withdraw
    //
    // off-chain:
    //
    //   getPlayerTickets( a, outcome )  -- how many tickets has address got on outcome
    //
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    //****************************************************
    // When a player makes a bet, the eth is distributed
    //****************************************************

    function potDistribution( uint256 amt ) private {

      uint256 parts = amt / 100;

      amtJP    += parts * 40;
      amtGP    += parts * 40;
      amtLP    += parts * 5;
      amtRP    += parts * 10;
      fee      += parts * 5;
  
    }


    //*********************
    // Record player's bet 
    //*********************
 
    function addBet( address a, uint256 outcome, uint256 tickets ) private {
    
      if( 0 == betsOf[a][outcome] ) {
        outcomeBetList[outcome].push(a);
      }

      betsOf[a][outcome] += tickets;

      outcomeTotalTickets[outcome] += tickets;
    }


    function checkOutcome( uint256 outcome ) private view {
      require(validOutcome[outcome], "Invalid outcome"); 
    }

    function strHash( string memory a ) public pure returns ( bytes32 ) {
        return( keccak256( abi.encodePacked( a ) ) );
    }

    function strEqHash( string memory a, bytes32 b ) private pure returns ( bool ) {
        return( keccak256( abi.encodePacked( a ) ) == b );
    }



    //***************************************
    // How many tickets has player purchased
    //***************************************

    function calcTickets( uint256 amt ) private view returns ( uint256 ) {

      require( amtToTicket[amt] > 0, "Invalid amt" ); 

      return amtToTicket[amt];
    } 


    //************************************************************
    // How many tickets does player have on a particular outcome
    //************************************************************

    function getPlayerTickets( address a, uint256 outcome ) public view returns ( uint256 numTickets ) {
      return betsOf[a][outcome]; 
    }


    //*******************************************
    // How many outcomes has this player bet on
    // including the one he wants to bet on
    //*******************************************

    function getPlayerOutcomesBet( address a, uint256 thisBetOutcome ) public view returns ( uint256 numOutcomesBet ) {
   
      for( uint256 i=0; i<validOutcomesList.length; i++ ) {
        uint256 v = validOutcomesList[i];
        if(v == thisBetOutcome || betsOf[a][v] > 0) {
          numOutcomesBet++;
        } 
      }
    }


    //*****************************************************
    // Player may not bet more than 10 tickets per outcome
    // Player may not bet on more than 3 outcomes
    //*****************************************************

    function checkMaxPlayerBets( address sender, uint256 outcome, uint256 tickets ) private view {
      require( getPlayerTickets( sender, outcome ) + tickets <= maxTicketsPerOutcome, "Exceeds player max tickets on outcome");
      require( getPlayerOutcomesBet( sender, outcome ) <= maxOutcomes, "Exceeds player max outcomes");
    }

    
    //*************************************************************************
    // Stop accepting bets on an outcome when 100 players have bet on it
    //*************************************************************************

    function checkMaxGameBets( uint256 outcome ) private view {
      require( outcomeBetList[outcome].length <= gameMaxBetsPerOutcome, "Exceeds game max on outcome");
    } 

    //*******************
    // Player places bet
    //*******************

    event Bet( bytes32 indexed gameId, address player, uint256 tickets, uint256 outcome );

    function bet( address player, uint256 amt, bytes32 gameId, uint256 outcome ) private {

      require( gameId == currentGameId, "Invalid game id");

      require( STATE_OPEN == currentGameState(), "Game not open");

      checkOutcome( outcome );                         // outcome bet on must be legal

      checkMaxGameBets( outcome );                     // check bets on this outcome are still allowed

      uint256 tickets = calcTickets( amt );            // amt bet must legal, calculate num tickets, zero amt will die here

      checkMaxPlayerBets( player, outcome, tickets );  // check player has not exceeded limits

      addBet( player, outcome, tickets );              // record the bet 

      potDistribution( amt );                          // record distribution of eth

      emit Bet( gameId, player, tickets, outcome ); 
    }


    //**************************************
    // external -- player bets with new eth
    //**************************************

    function betNew( bytes32 gameId, uint256 outcome ) external payable {

      bet( msg.sender, msg.value, gameId, outcome );
    }

    //**************************************************
    // external -- player bets using previous winnings
    //**************************************************

    event BetStash( address indexed account, uint256 amt );

    function betStash( bytes32 gameId, uint256 outcome, uint256 amt ) external {

      require(balanceOf[msg.sender] >= amt, "Stash too low");

      balanceOf[msg.sender] -= amt; 

      emit BetStash( msg.sender, amt );

      bet( msg.sender, amt, gameId, outcome );
    }


    //**********************
    // external -- withdraw
    //**********************

    event Withdraw( address indexed account, uint256 amount ); 

    function withdraw() public {
      require( balanceOf[msg.sender] > 0, "Account empty" );
      uint256 amount = balanceOf[msg.sender];
      balanceOf[msg.sender]=0;
      msg.sender.transfer(amount);
      emit Withdraw( msg.sender, amount );
    }


    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //
    // Game operator functions
    //
    // on-chain:
    //
    //   startNew( gid, duration )  -- reset storage, new game, event New, RollRP
    //
    //   finaliseCurrent( ... )  -- finalise game, pay players, event Finalise
    //                            + payment events: NoWin
    //                              or: PayJP, QueTicket, PayGP
    //   
    // off-chain:   
    //   
    //   selectWinner( gid, seed, outcome )  -- returns address of JP winner   
    //   
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


    //***************************************
    // Reset game storage
    //***************************************

    function resetStorage() private {

      for( uint256 i=0; i<validOutcomesList.length; i++ ) {
        uint256 v = validOutcomesList[i];
        for( uint256 n=0; n<outcomeBetList[v].length; n++ ) {
          address a = outcomeBetList[v][n];
          betsOf[a][v]=0;
        }
      }
 
      for( uint256 i=0; i<validOutcomesList.length; i++ ) {
        uint256 v = validOutcomesList[i];
        outcomeTotalTickets[v]=0;
        delete outcomeBetList[v];
      }

    }

    //***************************************************
    // External -- start a new game
    //***************************************************

    event New( bytes32 indexed gameId, uint256 closingTimestamp );
    event RollRP( bytes32 indexed gameId, uint256 portionJP, uint256 portionGP);

    function startNew( bytes32 gameId, uint256 duration ) public onlyOwner {

      require( STATE_FINAL == currentGameState(), "Game not final" );

      resetStorage();

      currentGameId = gameId;
    
      closingTimestamp = block.timestamp + duration;

      currentGameOutcome = 0;

      internalGameState = STATE_OPEN;
     
      emit New( gameId, closingTimestamp );

      // apportion the reserve fee to the JP and GP of the new game
      
      if ( amtRP > 0 ) {
        uint256 portionJP = amtRP.div( 2 );
        uint256 portionGP = amtRP.div( 2 );
        amtJP = amtJP.add( portionJP );
        amtGP = amtGP.add( portionGP );
        emit RollRP( gameId, portionJP, portionGP);
        amtRP = 0; 
      }

    }


    //********************************************************************************************
    // Return a number between 0 and max-1 
    // seed is the "private key" of the game, the hash of which is the gameId
    // players can't know the seed, so hashing it with anything gives an unpredictable outcome. 
    // game is already closed at this point, so they can't change things by placing bets
    //********************************************************************************************

    function rnd( uint256 max, string memory seed ) public view returns ( uint256 ) {
      bytes32 e = keccak256( abi.encodePacked( closingTimestamp, amtGP, seed, amtJP ) );
      return uint256(e).mod(max);
    }
  

    //*******************************
    // Offchain -- select JP winner
    //*******************************

    function selectWinner(bytes32 gameId, 
                          string memory seed, 
                          uint256 outcome
             ) public view returns( 
               uint256 winningTicket, 
               address winningAddress ) {

      require( currentGameId == gameId, "Bad gameId" );

      require( STATE_CLOSED == currentGameState() );

      uint256 numCorrectTickets = outcomeTotalTickets[outcome];

      winningTicket = rnd( numCorrectTickets, seed ); 
 
      uint256 ticketNumber=0;
      for( uint256 i=0; i<numCorrectTickets; i++ ) {
        winningAddress = outcomeBetList[outcome][i];
        ticketNumber += betsOf[winningAddress][outcome];
        if ( ticketNumber > winningTicket ) {
          return ( winningTicket, winningAddress );
        }
      }

      assert( false );  // should never happen
    }

    //*******************************
    // Record outcome, make payments
    //*******************************

    event NoWin( bytes32 indexed gameId );
    event PayJP( bytes32 indexed gameId, address winningAddress, uint256 winningTicket, uint256 amount );
    event PayGP( bytes32 indexed gameId, address payAddress, uint256 payAmount );
    event TakeFee( bytes32 indexed gameId, uint256 fee);

    function payout( bytes32 gameId, string memory seed, uint256 outcome, 
                           bool haveWinner, uint256 winningTicket, address winningAddress ) private {


      currentGameOutcome = outcome;
        
      //**********************
      // Payments, if any...
      //**********************

      if ( haveWinner ) {

        //*********************
        // Pay JP, mint RBT 
        //*********************

        emit PayJP( gameId, winningAddress, winningTicket, amtJP );
        
        balanceOf[winningAddress] = balanceOf[winningAddress].add( amtJP );

        amtJP = 0;        

        rbt.mint( winningAddress, 10**18 );  // 1 token
        

        //********
        // Pay LP
        //********

        uint256 rbtSupply = rbt.totalSupply();
        
        uint256 selectedHodler = rnd( rbtSupply, seed );

        rbt.queTicket.value(amtLP)( gameId, selectedHodler );  // emits QueTicket event

        amtLP = 0;        


        //*********
        // Pay GP
        //*********

        uint256 awardSlice = amtGP.div( outcomeTotalTickets[outcome] );

        for(uint256 i=0; i<outcomeBetList[outcome].length; i++) {
          address a = outcomeBetList[outcome][i];
          uint256 awardAmt = awardSlice.mul( betsOf[a][outcome] );
          balanceOf[a] = balanceOf[a].add(awardAmt);
          emit PayGP( gameId, a, awardAmt );
        }
        
        amtGP = 0;        

      } else {

        emit NoWin( gameId );

      }

      //**************************
      // Take fee out of contract
      //**************************

      if ( fee > 0 ) {
        Address.toPayable( owner() ).transfer( fee );
        emit TakeFee( gameId, fee );
        fee = 0;
      }

    } 


    //*****************************
    // External -- pay closed game 
    //*****************************

    event Finalise( bytes32 indexed gameId, uint256 outcome, string seed );

    function finaliseCurrent(bytes32 gameId, string memory seed, uint256 outcome, 
                             bool haveWinner, uint256 winningTicket, address winningAddress ) public onlyOwner {

      require( gameId == currentGameId, "Invalid game id");

      require( STATE_CLOSED == currentGameState(), "Game not closed" );

      require( strEqHash( seed, gameId ), "Bad seed");  // hashed seed is gameId

      emit Finalise( gameId, outcome, seed );

      payout( gameId, seed, outcome, haveWinner, winningTicket, winningAddress );
 
      internalGameState = STATE_FINAL; 
    }

}
