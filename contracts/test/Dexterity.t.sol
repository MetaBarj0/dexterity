// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { IDexterity } from "../src/interface/IDexterity.sol";

import { TokenA } from "./ERC20/TokenA.sol";
import { TokenB } from "./ERC20/TokenB.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Test, console } from "forge-std/Test.sol";

abstract contract DexterityTests is Test {
  IDexterity internal dex;
  TokenA internal tokenA;
  TokenB internal tokenB;
  address internal alice;
  uint256 aliceKey;

  function setUp() public {
    dex = new Dexterity();

    tokenA = new TokenA();
    tokenB = new TokenB();

    alice = makeAddr("alice");
  }

  function createPoolAB() internal {
    dex.createPool(address(tokenA), address(tokenB));
  }

  function depositAB(uint128 firstAmount, uint128 secondAmount) internal {
    dex.deposit(address(tokenA), address(tokenB), firstAmount, secondAmount);
  }

  function expectEmitPoolCreatedAB() internal {
    vm.expectEmit(true, true, false, false);
    emit IDexterity.PoolCreated(address(tokenA), address(tokenB), 0);
  }
}

contract DeployTests is DexterityTests {
  function test_deploy_creatorIsSet() public view {
    assertEq(dex.creator(), address(this));
  }
}

contract PoolCreationTests is DexterityTests {
  function test_createPool_fails_WithZeroTokenAddresses() public {
    vm.expectRevert(IDexterity.CreatePoolZeroAddress.selector);
    dex.createPool(address(0), address(0));

    vm.expectRevert(IDexterity.CreatePoolZeroAddress.selector);
    dex.createPool(address(tokenA), address(0));

    vm.expectRevert(IDexterity.CreatePoolZeroAddress.selector);
    dex.createPool(address(0), address(tokenA));
  }

  function test_createPool_fails_WithSameTokenAddress() public {
    vm.expectRevert(IDexterity.CreatePoolSameAddress.selector);
    dex.createPool(address(tokenA), address(tokenA));
  }

  function test_createPool_succeeds_WithValidTokenAddresses() public {
    expectEmitPoolCreatedAB();
    dex.createPool(address(tokenA), address(tokenB));
  }

  function test_createPool_fails_whenPoolAlreadyExists() public {
    dex.createPool(address(tokenA), address(tokenB));

    vm.expectRevert(IDexterity.PoolAlreadyExists.selector);
    dex.createPool(address(tokenA), address(tokenB));
  }
}

contract DepositTests is DexterityTests {
  function test_deposit_fails_withZeroAmount() public {
    vm.expectRevert(IDexterity.DepositInvalidAmount.selector);
    depositAB(uint128(0), uint128(0));

    vm.expectRevert(IDexterity.DepositInvalidAmount.selector);
    depositAB(uint128(1000), uint128(0));

    vm.expectRevert(IDexterity.DepositInvalidAmount.selector);
    depositAB(uint128(0), uint128(1000));
  }

  function test_deposit_fails_withZeroAddressForToken() public {
    vm.expectRevert(IDexterity.DepositZeroAddress.selector);
    dex.deposit(address(0), address(0), uint128(0), uint128(0));

    vm.expectRevert(IDexterity.DepositZeroAddress.selector);
    dex.deposit(address(tokenA), address(0), uint128(0), uint128(0));

    vm.expectRevert(IDexterity.DepositZeroAddress.selector);
    dex.deposit(address(0), address(tokenA), uint128(0), uint128(0));
  }

  function test_deposit_succeeds_withCorrectAmounts() public {
    tokenA.mintFor(alice, 3);
    tokenB.mintFor(alice, 6);

    vm.startPrank(alice);

    IERC20(tokenA).approve(address(dex), 3);
    IERC20(tokenB).approve(address(dex), 6);

    vm.expectEmit();
    emit IDexterity.Deposited(address(tokenA), address(tokenB), 1, 2);
    depositAB(uint128(1), uint128(2));

    vm.expectEmit();
    emit IDexterity.Deposited(address(tokenA), address(tokenB), 2, 4);
    depositAB(uint128(2), uint128(4));

    IDexterity.Pool memory poolAB = dex.getPool(address(tokenA), address(tokenB));

    assertEq(tokenA.balanceOf(alice), 0);
    assertEq(tokenB.balanceOf(alice), 0);
    assertEq(poolAB.firstReserve, 3);
    assertEq(poolAB.secondReserve, 6);

    vm.stopPrank();
  }
}
