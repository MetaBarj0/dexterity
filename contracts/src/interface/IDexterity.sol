// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title IDexterity: the interface of the decentralized exchange
/// @author crypt0
/// @notice Contains type, error and event definitions usable in a concrete
///         type. Also contains mandatory functions to implement.
/// @dev Nothing particular
interface IDexterity {
  /// @notice Represents a pool supported by IDexterity
  /// @dev token address are not necessarily meant to be ordered. Pool
  ///      instances can be a member of a mapping.
  struct Pool {
    uint128 firstReserve;
    uint128 secondReserve;
    address firstToken;
    address secondToken;
  }

  error DepositInvalidAmount();
  error DepositZeroAddress();
  error DepositSameToken();
  error DepositOverflowing();
  error WithdrawNotEnoughShares();
  error SwapSameToken();
  error SwapInvalidAmount();
  error SwapInsufficientLiquidity();

  /// @notice triggered when a forward to uniswap v2 router 02 failed
  error SwapUniswapForwardFailure();

  event PoolCreated(address indexed firstToken, address indexed secondToken, uint256 indexed poolId);
  event Deposited(address indexed firstToken, address indexed secondToken, uint256 firstAmount, uint256 secondAmount);
  event Withdrawn(
    address indexed firstToken,
    address indexed secondToken,
    uint128 shares,
    uint128 firstTokenAmount,
    uint128 secondTokenAmount
  );
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
