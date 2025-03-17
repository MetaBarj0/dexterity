// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDexterity {
  error CreatePairZeroAddress();
  error CreatePairAlreadyExists();

  struct Pair {
    address token0;
    address token1;
  }

  function createPair(address token0, address token1) external returns (uint256 pairId);
}
