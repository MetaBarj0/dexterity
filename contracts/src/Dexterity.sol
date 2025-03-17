// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDexterity } from "./interfaces/IDexterity.sol";

contract Dexterity is IDexterity {
  address public immutable creator;
  mapping(uint256 pairId => Pair pair) public pairs;

  constructor() {
    creator = msg.sender;
  }

  function createPair(address token0, address token1) external override returns (uint256 pairId) {
    require(address(token0) != address(0) && address(token1) != address(0), CreatePairZeroAddress());

    (address lesserToken, address greaterToken) = token0 < token1 ? (token0, token1) : (token1, token0);

    pairId = _computePairId(lesserToken, greaterToken);

    Pair storage pair = pairs[pairId];

    require(pair.token0 == address(0) && pair.token1 == address(0), CreatePairAlreadyExists());

    pair.token0 = lesserToken;
    pair.token1 = greaterToken;
  }

  function _computePairId(address token0, address token1) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(token0, token1)));
  }
}
