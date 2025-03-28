// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IDexterity {
  struct Pool {
    uint128 firstReserve;
    uint128 secondReserve;
    address firstToken;
    address secondToken;
  }

  error PoolUnexisting();
  error PoolAlreadyExists();
  error DepositInvalidAmount();
  error DepositZeroAddress();
  error DepositSameToken();
  error DepositOverflowing();
  error WithdrawNotEnoughShares();
  error SwapSameToken();
  error SwapInvalidAmount();
  error SwapUniswapForwardFailure();
  error SwapInsufficientLiquidity();

  event PoolCreated(address indexed firstToken, address indexed secondToken, uint256 indexed poolId);
  event Deposited(address indexed firstToken, address indexed secondToken, uint256 firstAmount, uint256 secondAmount);
  event Swapped(
    address indexed sender,
    address indexed firstToken,
    address indexed secondToken,
    uint256 firstAmount,
    uint256 secondAmount
  );

  function creator() external view returns (address);
  function getPool(address firstToken, address secondToken) external view returns (Pool memory);
  function deposit(address firstToken, address secondToken, uint128 firstAmount, uint128 secondAmount) external;
  function withdraw(address firstToken, address secondToken, uint128 shares) external;
  function swap(address sourceToken, uint128 amount, address destinationToken) external;
}
