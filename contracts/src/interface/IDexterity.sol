// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDexterity {
  struct Pool {
    address firstToken;
    address secondToken;
    uint128 firstReserve;
    uint128 secondReserve;
  }

  error CreatePoolZeroAddress();
  error CreatePoolSameAddress();
  error PoolUnexisting();
  error PoolAlreadyExists();
  error DepositInvalidAmount();
  error DepositZeroAddress();
  error WithdrawNotEnoughShares();

  event PoolCreated(address indexed firstToken, address indexed secondToken, uint256 indexed poolIndex);
  event Deposited(address indexed firstToken, address indexed secondToken, uint256 firstAmount, uint256 secondAmount);

  function creator() external view returns (address);
  function createPool(address firstToken, address secondToken) external;
  function getPool(address firstToken, address secondToken) external view returns (Pool memory);
  function deposit(address firstToken, address secondToken, uint128 firstAmount, uint128 secondAmount) external;
  function withdraw(address firstToken, address secondToken, uint256 shares) external;
}
