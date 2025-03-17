// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDexterity {
  error CreateERC20PairZeroAddress();
  error CreateERC20PairAlreadyExists();
  error CreateERC20EtherPairZeroAddress();
  error CreateERC20EtherPairAlreadyExists();

  struct ERC20Pair {
    address token0;
    address token1;
  }

  function createERC20Pair(address token0, address token1) external returns (uint256 pairId);
  function createERC20EtherPair(address token) external returns (uint256 pairId);
}
