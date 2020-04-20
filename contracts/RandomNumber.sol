pragma solidity ^0.5.8;

import "./openzeppelin-solidity/contracts/math/SafeMath.sol";

contract RandomNumber {
   
  using SafeMath for uint256;

  bytes32 previousHash = 0x0;

  uint256 public rnd;

  // random number between 0 and maxInclusive

  function rndGenerate(uint256 maxInclusive) internal returns (uint256) {
    previousHash = keccak256(abi.encodePacked(block.timestamp, block.difficulty, previousHash));
    rnd = uint256(previousHash).mod(maxInclusive);
    return rnd;
  }

  // same but pass in some extra randomness 'x'

  function rndGenerate(uint256 maxInclusive, uint256 x) internal returns (uint256) {
    previousHash = keccak256(abi.encodePacked(block.timestamp, block.difficulty, previousHash, x));
    rnd = uint256(previousHash).mod(maxInclusive);
    return rnd;
  }

}
