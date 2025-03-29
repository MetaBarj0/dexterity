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

  /// @dev zero amount deposit for one or both tokens
  error DepositInvalidAmount();

  /// @dev one or both token are zero address
  error DepositZeroAddress();

  /// @dev both tokens have the same address
  error DepositSameToken();

  /// @dev overflowing deposit. Due to how share are calculated, reserves must
  ///      hold in an uint128 storage space.
  error DepositOverflowing();

  /// @dev holder attempts to withdraw more share than he has
  error WithdrawNotEnoughShares();

  /// @dev trader attemps to swap same token
  error SwapSameToken();

  /// @dev trader attempts to swap zero token
  error SwapInvalidAmount();

  /// @dev the pool does not have enough liquidity to perform the swap
  error SwapInsufficientLiquidity();

  /// @dev triggered when a forward to uniswap v2 router 02 failed
  error SwapUniswapForwardFailure();

  /// @dev emitted only whe the first deposit is made into a pool.
  event PoolCreated(address indexed firstToken, address indexed secondToken, uint256 indexed poolId);

  /// @dev deposit successfully done emit this event
  event Deposited(address indexed firstToken, address indexed secondToken, uint256 firstAmount, uint256 secondAmount);

  /// @dev successful withdraws emit this event
  event Withdrawn(
    address indexed firstToken,
    address indexed secondToken,
    uint128 shares,
    uint128 firstTokenAmount,
    uint128 secondTokenAmount
  );

  // TODO: rename source and destination to in and out
  /// @dev successful swaps emit this event
  event Swapped(
    address indexed sender,
    address indexed sourceToken,
    address indexed destinationToken,
    uint256 sourceAmount,
    uint256 destinationAmount
  );

  /// @notice returns the creator of this IDexterity instance.
  /// @return the creator, the one.
  function creator() external view returns (address);

  /// @notice Obtain a copy of a pool specified by token addresses
  /// @dev Order of the specified tokens does not matter (see getPoolId_ in
  ///      Dexterity implementation)
  /// @param firstToken is a token address
  /// @param secondToken is a token address
  /// @return a copy of a pool in a mpping in the implementation for example
  ///         (see pools_ state variable in Dexterity implementation)
  function getPool(address firstToken, address secondToken) external view returns (Pool memory);

  /// @notice Perform a deposit
  /// @dev Note the uint128 storage space for amounts.
  /// @param firstToken a token address used to get the pool
  /// @param secondToken a token address used to get the pool
  /// @param firstAmount an amount for the first token
  /// @param secondAmount an amount for the second token
  function deposit(address firstToken, address secondToken, uint128 firstAmount, uint128 secondAmount) external;

  /// @notice allow a holder to withdraw his liquidity
  /// @dev Note the storage type of shares
  /// @param firstToken a token address used to get the pool and credit the holder
  /// @param secondToken a token address used to get the pool and credit the holder
  /// @param shares the share amount to withdraw
  function withdraw(address firstToken, address secondToken, uint128 shares) external;

  /// @notice Perform a swapIn
  /// @dev Note the storage type for amount. This is a swapIn, it means it
  ///      takes an exact amount of input token to convert to a computed amount
  ///      of output token
  /// @param sourceToken the token to swap from
  /// @param amount the amount of input token to swap
  /// @param destinationToken the token to swap to
  function swapIn(address sourceToken, uint128 amount, address destinationToken) external;

  /// @notice Perform a swapOut
  /// @dev Note the storage type for amount. This is a swapOut, it means it
  ///      gives an exact amount of output token from a computed amount of
  ///      input token
  /// @param destinationToken the token to swap to
  /// @param amount the amount of wanted output token
  /// @param sourceToken the token to swap from
  function swapOut(address destinationToken, uint128 amount, address sourceToken) external;
}
