// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDexterity } from "./interface/IDexterity.sol";

import { IUniswapV2Router02 } from "./interface/IUniswapV2Router02.sol";
import { Maths } from "./library/Maths.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

contract Dexterity is IDexterity {
  address private immutable creator_;
  bool locked_;

  mapping(uint256 poolId => Pool) private pools_;
  mapping(uint256 poolId => mapping(address holder => uint128)) private holderPoolShares_;
  mapping(uint256 poolId => uint128) private totalPoolShares_;

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

  function sharesOf(address holder, address firstToken, address secondToken) external view returns (uint128) {
    return holderPoolShares_[computePoolId_(firstToken, secondToken)][holder];
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

    unchecked {
      require(uint256(pool.firstReserve) + uint256(firstAmount) <= type(uint128).max, DepositOverflowing());
      require(uint256(pool.secondReserve) + uint256(secondAmount) <= type(uint128).max, DepositOverflowing());
    }

    if (pool.firstReserve == 0) {
      pool.firstToken = firstToken;
      pool.secondToken = secondToken;

      emit PoolCreated(firstToken, secondToken, poolId);
    }

    unchecked {
      if (pool.firstToken == firstToken) {
        pool.firstReserve += firstAmount;
        pool.secondReserve += secondAmount;
      } else {
        pool.secondReserve += firstAmount;
        pool.firstReserve += secondAmount;
      }

      uint128 shares = uint128(Maths.sqrt(uint256(firstAmount) * secondAmount));
      holderPoolShares_[poolId][msg.sender] += shares;
      totalPoolShares_[poolId] += shares;
    }

    emit Deposited(msg.sender, firstToken, secondToken, firstAmount, secondAmount);

    IERC20(firstToken).safeTransferFrom(msg.sender, address(this), firstAmount);
    IERC20(secondToken).safeTransferFrom(msg.sender, address(this), secondAmount);
  }

  function withdraw(address firstToken, address secondToken, uint128 shares) external override {
    uint256 poolId = computePoolId_(firstToken, secondToken);

    require(shares > 0 && holderPoolShares_[poolId][msg.sender] >= shares, WithdrawNotEnoughShares());

    uint256 poolFirstTokenBalance = IERC20(firstToken).balanceOf(address(this));
    uint256 poolSecondTokenBalance = IERC20(secondToken).balanceOf(address(this));

    uint128 poolShares = totalPoolShares_[poolId];

    uint128 firstTokenAmount = uint128((uint256(shares) * poolFirstTokenBalance));
    uint128 secondTokenAmount = uint128((uint256(shares) * poolSecondTokenBalance));

    // Pool shares canot be 0
    assembly {
      firstTokenAmount := div(firstTokenAmount, poolShares)
      secondTokenAmount := div(secondTokenAmount, poolShares)
    }

    holderPoolShares_[poolId][msg.sender] -= shares;
    totalPoolShares_[poolId] -= shares;

    Pool storage pool = pools_[poolId];

    if (firstToken == pool.firstToken) {
      pool.firstReserve -= uint128(firstTokenAmount);
      pool.secondReserve -= uint128(secondTokenAmount);
    } else {
      pool.secondReserve -= uint128(firstTokenAmount);
      pool.firstReserve -= uint128(secondTokenAmount);
    }

    emit Withdrawn(firstToken, secondToken, shares, firstTokenAmount, secondTokenAmount);

    IERC20(firstToken).safeTransfer(msg.sender, firstTokenAmount);
    IERC20(secondToken).safeTransfer(msg.sender, secondTokenAmount);
  }

  function swapIn(address tokenIn, uint128 amountIn, address tokenOut) external override {
    require(tokenIn != tokenOut, SwapSameToken());
    require(amountIn > 0, SwapInvalidAmount());

    uint256 poolId = computePoolId_(tokenIn, tokenOut);
    Pool storage pool = pools_[poolId];

    (uint128 reserveIn, uint128 reserveOut) = getReserves_(pool, tokenIn);

    // a reserve at 0 means the pool is not supported by dexterity (not created)
    require(reserveIn == 0 || reserveIn >= amountIn, SwapInsufficientLiquidity());

    if (reserveIn == 0) {
      uniswapSwapExactTokensForTokens_(tokenIn, amountIn, tokenOut);
      return;
    }

    uint256 numerator = uint256(reserveOut) * uint256(amountIn) * 997;
    uint256 denominator = uint256(reserveIn) * 1000 + uint256(amountIn) * 997;
    uint128 amountOut = uint128(numerator / denominator);

    updateReserves_(pool, tokenIn, tokenOut, amountIn, amountOut);

    emit Swapped(msg.sender, tokenIn, tokenOut, amountIn * 997 / 1000, amountOut);

    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
    IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
  }

  function swapOut(address tokenOut, uint128 amountOut, address tokenIn) external override {
    require(tokenOut != tokenIn, SwapSameToken());
    require(amountOut > 0, SwapInvalidAmount());

    uint256 poolId = computePoolId_(tokenOut, tokenIn);
    Pool storage pool = pools_[poolId];

    (uint128 reserveIn, uint128 reserveOut) = getReserves_(pool, tokenIn);

    // a reserve at 0 means the pool is not supported by dexterity (not created)
    require(reserveOut == 0 || reserveOut >= amountOut, SwapInsufficientLiquidity());

    if (reserveOut == 0) {
      uniswapSwapTokensForExactTokens_(tokenOut, amountOut, tokenIn);
      return;
    }

    uint256 numerator = uint256(reserveIn) * amountOut * 1000;
    uint256 denominator = (uint256(reserveOut) - amountOut) * 997;
    uint128 amountIn = uint128(numerator / denominator) + 1;

    updateReserves_(pool, tokenIn, tokenOut, amountIn, amountOut);

    emit Swapped(msg.sender, tokenIn, tokenOut, amountIn * 997 / 1000, amountOut);

    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
    IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
  }

  function computePoolId_(address firstToken, address secondToken) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(bytes20(firstToken) ^ bytes20(secondToken))));
  }

  modifier preventReentrancy() {
    require(!locked_, DexterityReentrancy());

    locked_ = true;
    _;
    locked_ = false;
  }

  function uniswapSwapExactTokensForTokens_(address tokenIn, uint256 amountIn, address tokenOut)
    internal
    preventReentrancy
  {
    emit Swapped(msg.sender, tokenIn, tokenOut, 0, 0);

    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
    IERC20(tokenIn).safeTransfer(creator_, amountIn * 2 / 1000);

    uint256 amountMinusCreatorFee = amountIn * 998 / 1000; // creator fee model: 0.02%

    address uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    if (!IERC20(tokenIn).approve(uniswap, amountMinusCreatorFee)) {
      revert SwapUniswapForwardFailure();
    }

    IUniswapV2Router02 router = IUniswapV2Router02(uniswap);

    address[] memory path = new address[](2);

    path[0] = tokenIn;
    path[1] = tokenOut;

    try router.swapExactTokensForTokens(amountMinusCreatorFee, 0, path, msg.sender, type(uint256).max) returns (
      uint256[] memory /*ignored*/
    ) {
      // ignore return value, unuseful in Dexterity
    } catch (bytes memory) {
      revert SwapUniswapForwardFailure();
    }
  }

  function uniswapSwapTokensForExactTokens_(address tokenOut, uint256 amountOut, address tokenIn)
    internal
    preventReentrancy
  {
    emit Swapped(msg.sender, tokenIn, tokenOut, 0, 0);

    uint256 tokenInAllowance = IERC20(tokenIn).allowance(msg.sender, address(this));
    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenInAllowance);

    address uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    if (!IERC20(tokenIn).approve(uniswap, tokenInAllowance)) {
      revert SwapUniswapForwardFailure();
    }

    IUniswapV2Router02 router = IUniswapV2Router02(uniswap);

    address[] memory path = new address[](2);

    path[0] = tokenIn;
    path[1] = tokenOut;

    uint256 tokenInBalanceBeforeSwap = IERC20(tokenIn).balanceOf(address(this));

    try router.swapTokensForExactTokens(amountOut, tokenInAllowance, path, msg.sender, type(uint256).max) returns (
      uint256[] memory /*ignored*/
    ) {
      //ignore return value, unuseful in Dexterity
    } catch (bytes memory) {
      revert SwapUniswapForwardFailure();
    }

    uint256 tokenInBalanceAfterSwap = IERC20(tokenIn).balanceOf(address(this));

    uint256 spent = tokenInBalanceBeforeSwap - tokenInBalanceAfterSwap;
    uint256 creatorFee = spent * 2 / 1000;

    require(tokenInBalanceAfterSwap > creatorFee, SwapUniswapForwardFailure());

    uint256 refund = tokenInBalanceAfterSwap - creatorFee;

    IERC20(tokenIn).safeTransfer(creator(), creatorFee);
    IERC20(tokenIn).safeTransfer(msg.sender, refund);
  }

  function getReserves_(Pool storage pool, address tokenIn)
    private
    view
    returns (uint128 reserveIn, uint128 reserveOut)
  {
    (reserveIn, reserveOut) =
      tokenIn == pool.firstToken ? (pool.firstReserve, pool.secondReserve) : (pool.secondReserve, pool.firstReserve);
  }

  function updateReserves_(Pool storage pool, address tokenIn, address tokenOut, uint128 amountIn, uint128 amountOut)
    private
  {
    if (tokenIn == pool.firstToken) {
      pool.firstReserve += amountIn;
      pool.secondReserve -= amountOut;
    } else {
      pool.secondReserve += amountIn;
      pool.firstReserve -= amountOut;
    }

    emit PoolUpdated(computePoolId_(tokenIn, tokenOut), tokenIn, tokenOut, int128(amountIn), -int128(amountOut));
  }
}
