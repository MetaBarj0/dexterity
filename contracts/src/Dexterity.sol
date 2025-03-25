// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDexterity } from "./interface/IDexterity.sol";
import { Maths } from "./library/Maths.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

using Maths for uint256;

contract Dexterity is IDexterity {
  address private immutable creator_;

  mapping(uint256 poolId => Pool) private pools_;

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

    IERC20(firstToken).transferFrom(msg.sender, address(this), firstAmount);
    IERC20(secondToken).transferFrom(msg.sender, address(this), secondAmount);

    uint256 poolId = computePoolId_(firstToken, secondToken);
    Pool storage pool = pools_[poolId];
    pool.firstReserve += firstAmount;
    pool.secondReserve += secondAmount;

    emit Deposited(firstToken, secondToken, firstAmount, secondAmount);
  }

  function computePoolId_(address firstToken, address secondToken) private pure returns (uint256) {
    (address lesserPool, address greaterPool) =
      firstToken < secondToken ? (firstToken, secondToken) : (secondToken, firstToken);

    return uint256(keccak256(abi.encodePacked(lesserPool, greaterPool)));
  }
}
