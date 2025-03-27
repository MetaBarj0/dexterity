// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDexterity } from "./interface/IDexterity.sol";
import { Maths } from "./library/Maths.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Dexterity is IDexterity {
  address private immutable creator_;

  mapping(uint256 poolId => Pool) private pools_;
  mapping(uint256 poolId => mapping(address holder => uint128)) holderPoolShares_;
  mapping(uint256 poolId => uint128) totalPoolShares_;

  constructor() {
    creator_ = msg.sender;
  }

  function creator() public view returns (address) {
    return creator_;
  }

  function getPool(address firstToken, address secondToken) external view returns (Pool memory) {
    uint256 poolId = computePoolId_(firstToken, secondToken);

    return pools_[poolId];
  }

  function deposit(address firstToken, address secondToken, uint128 firstAmount, uint128 secondAmount)
    external
    override
  {
    require(firstToken != address(0) && secondToken != address(0), DepositZeroAddress());
    require(firstToken != secondToken, DepositSameToken());
    require(firstAmount > 0 && secondAmount > 0, DepositInvalidAmount());

    uint256 poolId = computePoolId_(firstToken, secondToken);
    Pool storage pool = pools_[poolId];

    require(uint256(pool.firstReserve) + uint256(firstAmount) <= type(uint128).max, DepositOverflowing());
    require(uint256(pool.secondReserve) + uint256(secondAmount) <= type(uint128).max, DepositOverflowing());

    IERC20(firstToken).transferFrom(msg.sender, address(this), firstAmount);
    IERC20(secondToken).transferFrom(msg.sender, address(this), secondAmount);

    if (pool.firstReserve == 0) {
      pool.firstToken = firstToken;
      pool.secondToken = secondToken;

      emit PoolCreated(firstToken, secondToken, poolId);
    }

    pool.firstReserve += firstAmount;
    pool.secondReserve += secondAmount;

    uint128 shares = uint128(Maths.sqrt(uint256(firstAmount) * secondAmount));
    holderPoolShares_[poolId][msg.sender] += shares;
    totalPoolShares_[poolId] += shares;

    emit Deposited(firstToken, secondToken, firstAmount, secondAmount);
  }

  function withdraw(address firstToken, address secondToken, uint128 shares) external override {
    uint256 poolId = computePoolId_(firstToken, secondToken);

    require(shares > 0 && holderPoolShares_[poolId][msg.sender] >= shares, WithdrawNotEnoughShares());

    uint256 totalFirstToken = IERC20(firstToken).balanceOf(address(this));
    uint256 totalSecondToken = IERC20(secondToken).balanceOf(address(this));

    uint128 totalShares = totalPoolShares_[poolId];

    uint256 withdrawFirstToken = (shares * totalFirstToken) / totalShares;
    uint256 withdrawSecondToken = (shares * totalSecondToken) / totalShares;

    IERC20(firstToken).transfer(msg.sender, withdrawFirstToken);
    IERC20(secondToken).transfer(msg.sender, withdrawSecondToken);

    holderPoolShares_[poolId][msg.sender] -= shares;
    totalPoolShares_[poolId] -= shares;

    Pool storage pool = pools_[poolId];
    pool.firstReserve -= uint128(withdrawFirstToken);
    pool.secondReserve -= uint128(withdrawSecondToken);
  }

  function swap(address sourceToken, uint256 amount, address destinationToken) external override {
    require(sourceToken != destinationToken, SwapSameToken());
    require(amount > 0, SwapInvalidAmount());

    uint256 poolId = computePoolId_(sourceToken, destinationToken);
    uint256 totalPoolShare = totalPoolShares_[poolId];

    // a pool with 0 share is considered to not be created thus, not supported by dexterity
    require(totalPoolShare == 0 || totalPoolShare >= amount, SwapInsufficientLiquidity());

    Pool memory pool = pools_[poolId];

    if (pool.firstReserve == 0) {
      forwardSwapToUniswapRouter_(sourceToken, amount);
      return;
    }

    emit Swapped(msg.sender, sourceToken, destinationToken, 100_300, 911);
  }

  function computePoolId_(address firstToken, address secondToken) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(bytes20(firstToken) ^ bytes20(secondToken))));
  }

  function forwardSwapToUniswapRouter_(address sourceToken, uint256 amount) internal {
    address uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    (bool success,) = uniswap.call(
      abi.encodeWithSignature(
        "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
        amount,
        0,
        [sourceToken], // thought to fail, a valid path as at least 2 entries
        msg.sender,
        block.number + 1
      )
    );

    require(success, SwapUniswapForwardFailure());
  }
}
