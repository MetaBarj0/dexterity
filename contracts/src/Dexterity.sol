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

  function createPool(address firstToken, address secondToken) external override {
    require(firstToken != address(0) && secondToken != address(0), CreatePoolZeroAddress());
    require(firstToken != secondToken, CreatePoolSameAddress());

    uint256 poolId = computePoolId_(firstToken, secondToken);
    require(pools_[poolId].firstToken == address(0), PoolAlreadyExists());

    pools_[poolId] = Pool({ firstToken: firstToken, secondToken: secondToken, firstReserve: 0, secondReserve: 0 });

    emit PoolCreated(firstToken, secondToken, poolId);
  }

  function deposit(address firstToken, address secondToken, uint128 firstAmount, uint128 secondAmount)
    external
    override
  {
    require(firstToken != address(0) && secondToken != address(0), DepositZeroAddress());
    require(firstAmount > 0 && secondAmount > 0, DepositInvalidAmount());

    uint256 poolId = computePoolId_(firstToken, secondToken);
    Pool storage pool = pools_[poolId];

    require(uint256(pool.firstReserve) + uint256(firstAmount) <= type(uint128).max, DepositOverflowing());
    require(uint256(pool.secondReserve) + uint256(secondAmount) <= type(uint128).max, DepositOverflowing());

    IERC20(firstToken).transferFrom(msg.sender, address(this), firstAmount);
    IERC20(secondToken).transferFrom(msg.sender, address(this), secondAmount);

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

    uint256 withdrawFirstToken = shares * totalFirstToken / totalShares;
    uint256 withdrawSecondToken = shares * totalSecondToken / totalShares;

    IERC20(firstToken).transfer(msg.sender, withdrawFirstToken);
    IERC20(secondToken).transfer(msg.sender, withdrawSecondToken);

    holderPoolShares_[poolId][msg.sender] -= shares;
    totalPoolShares_[poolId] -= shares;

    Pool storage pool = pools_[poolId];
    pool.firstReserve -= uint128(withdrawFirstToken);
    pool.secondReserve -= uint128(withdrawSecondToken);
  }

  function computePoolId_(address firstToken, address secondToken) private pure returns (uint256) {
    (address lesserPool, address greaterPool) =
      firstToken < secondToken ? (firstToken, secondToken) : (secondToken, firstToken);

    return uint256(keccak256(abi.encodePacked(lesserPool, greaterPool)));
  }
}
