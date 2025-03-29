// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDexterity } from "./interface/IDexterity.sol";

import { IUniswapV2Router02 } from "./interface/IUniswapV2Router02.sol";
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

    uint256 poolFirstTokenBalance = IERC20(firstToken).balanceOf(address(this));
    uint256 poolSecondTokenBalance = IERC20(secondToken).balanceOf(address(this));

    uint128 poolShares = totalPoolShares_[poolId];

    uint128 firstTokenAmount = uint128((uint256(shares) * poolFirstTokenBalance) / poolShares);
    uint128 secondTokenAmount = uint128((uint256(shares) * poolSecondTokenBalance) / poolShares);

    IERC20(firstToken).transfer(msg.sender, firstTokenAmount);
    IERC20(secondToken).transfer(msg.sender, secondTokenAmount);

    holderPoolShares_[poolId][msg.sender] -= shares;
    totalPoolShares_[poolId] -= shares;

    Pool storage pool = pools_[poolId];
    pool.firstReserve -= uint128(firstTokenAmount);
    pool.secondReserve -= uint128(secondTokenAmount);

    emit Withdrawn(firstToken, secondToken, shares, firstTokenAmount, secondTokenAmount);
  }

  function swapIn(address sourceToken, uint128 amount, address destinationToken) external override {
    require(sourceToken != destinationToken, SwapSameToken());
    require(amount > 0, SwapInvalidAmount());

    uint256 poolId = computePoolId_(sourceToken, destinationToken);
    Pool storage pool = pools_[poolId];

    uint128 reserveIn = sourceToken == pool.firstToken ? pool.firstReserve : pool.secondReserve;

    // a reserve at 0 means the pool is not supported by dexterity (not created)
    require(reserveIn == 0 || reserveIn >= amount, SwapInsufficientLiquidity());

    if (reserveIn == 0) {
      uniswapSwapExactTokensForTokens_(sourceToken, amount, destinationToken);
      return;
    }

    uint128 reserveOut = destinationToken == pool.firstToken ? pool.firstReserve : pool.secondReserve;
    uint256 amountIn = uint256(amount) * 997; // hardcoded fee model, could be part of a pool definition
    uint256 numerator = uint256(reserveOut) * amountIn;
    uint256 denominator = uint256(reserveIn) * 1000 + amountIn;
    uint128 amountOut = uint128(numerator / denominator);

    IERC20(sourceToken).transferFrom(msg.sender, address(this), amount);
    IERC20(destinationToken).transfer(msg.sender, amountOut);

    // TODO: cover both branches. Can be done when I will implement swapOut mechanic
    if (sourceToken == pool.firstToken) {
      pool.firstReserve += amount;
      pool.secondReserve -= amountOut;
    } else {
      pool.secondReserve += amount;
      pool.firstReserve -= amountOut;
    }

    emit Swapped(msg.sender, sourceToken, destinationToken, amount, amountOut);
  }

  function swapOut(address destinationToken, uint128 amount, address sourceToken) external override {
    require(destinationToken != sourceToken, SwapSameToken());
    require(amount > 0, SwapInvalidAmount());

    uint256 poolId = computePoolId_(destinationToken, sourceToken);
    Pool storage pool = pools_[poolId];

    uint128 reserveOut = destinationToken == pool.firstToken ? pool.firstReserve : pool.secondReserve;

    // a reserve at 0 means the pool is not supported by dexterity (not created)
    require(reserveOut == 0 || reserveOut >= amount, SwapInsufficientLiquidity());

    if (reserveOut == 0) {
      uniswapSwapTokensForExactTokens_(destinationToken, amount, sourceToken);
      return;
    }

    uint128 reserveIn = sourceToken == pool.firstToken ? pool.firstReserve : pool.secondReserve;
    uint256 numerator = uint256(reserveIn) * amount * 1000;
    uint256 denominator = (uint256(reserveOut) - amount) * 997;
    uint128 amountIn = uint128(numerator / denominator);

    IERC20(destinationToken).transfer(msg.sender, amount);
    IERC20(sourceToken).transferFrom(msg.sender, address(this), amountIn);

    // TODO: cover both branches. Can be done when I will implement swapOut mechanic
    if (sourceToken == pool.firstToken) {
      pool.firstReserve += amountIn;
      pool.secondReserve -= amount;
    } else {
      pool.secondReserve += amountIn;
      pool.firstReserve -= amount;
    }

    emit Swapped(msg.sender, sourceToken, destinationToken, amountIn, amount);
  }

  function computePoolId_(address firstToken, address secondToken) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(bytes20(firstToken) ^ bytes20(secondToken))));
  }

  function uniswapSwapExactTokensForTokens_(address sourceToken, uint256 amount, address destinationToken) internal {
    IERC20(sourceToken).transferFrom(msg.sender, address(this), amount);
    IERC20(sourceToken).transfer(creator_, amount * 2 / 1000);

    uint256 amountMinusCreatorFee = amount * 998 / 1000; // creator fee model: 0.02%

    address uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IERC20(sourceToken).approve(uniswap, amountMinusCreatorFee);

    IUniswapV2Router02 router = IUniswapV2Router02(uniswap);

    address[] memory path = new address[](2);

    path[0] = sourceToken;
    path[1] = destinationToken;

    try router.swapExactTokensForTokens(amountMinusCreatorFee, 0, path, msg.sender, type(uint256).max) returns (
      uint256[] memory amounts
    ) {
      emit Swapped(msg.sender, sourceToken, destinationToken, amount, amounts[1]);
    } catch Error(string memory) {
      revert SwapUniswapForwardFailure();
    } catch (bytes memory) {
      revert SwapUniswapForwardFailure();
    }
  }

  function uniswapSwapTokensForExactTokens_(address destinationToken, uint256 amount, address sourceToken) internal {
    revert SwapUniswapForwardFailure();
  }
}
