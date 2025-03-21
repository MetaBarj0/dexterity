// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDexterity {
  error CreateERC20OnlyPairZeroAddress();
  error CreateERC20OnlyPairSameAddress();
  error CreateERC20OnlyPairAlreadyExists();
  error CreateERC20EtherPairZeroAddress();
  error CreateERC20EtherPairAlreadyExists();
  error DepositERC20OnlyUnhandledToken();
  error DepositERC20OnlyInsufficientAmount();

  struct ERC20Pair {
    address token0;
    address token1;
  }

  event ERC20OnlyPairCreated(address indexed token0, address indexed token1, uint256 indexed pairId);
  event ERC20EtherPairCreated(address indexed token, uint256 indexed pairId);

  function createERC20OnlyPair(address token0, address token1) external returns (uint256 pairId);
  function createERC20EtherPair(address token) external returns (uint256 pairId);
  function depositERC20Only(address token0, address token1, uint256 token0Amount, uint256 token1Amount) external;
}
