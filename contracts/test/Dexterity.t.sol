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
  address internal bob;
  address internal chuck;

  function setUp() public {
    dex = new Dexterity();

    tokenA = new TokenA();
    tokenB = new TokenB();

    alice = makeAddr("alice");
    bob = makeAddr("bob");
    chuck = makeAddr("chuck");
  }

  function depositAB(uint128 firstAmount, uint128 secondAmount) internal {
    dex.deposit(address(tokenA), address(tokenB), firstAmount, secondAmount);
  }

  function withdrawAB(uint128 shares) internal {
    dex.withdraw(address(tokenA), address(tokenB), shares);
  }

  function expectEmitPoolCreatedAB() internal {
    vm.expectEmit(true, true, false, false);
    emit IDexterity.PoolCreated(address(tokenA), address(tokenB), 0);
  }

  function mintTokenABFor(address holder, uint256 amountA, uint256 amountB) internal {
    tokenA.mintFor(holder, amountA);
    tokenB.mintFor(holder, amountB);
  }

  function holderDepositAB(address holder, uint128 amountA, uint128 amountB) internal {
    vm.startPrank(holder);

    tokenA.approve(address(dex), amountA);
    tokenB.approve(address(dex), amountB);

    dex.deposit(address(tokenA), address(tokenB), amountA, amountB);

    vm.stopPrank();
  }

  function getPoolABInvariant() internal view returns (uint256) {
    IDexterity.Pool memory pool = dex.getPool(address(tokenA), address(tokenB));

    return pool.firstReserve * pool.secondReserve;
  }

  function assertPoolReserveABEq(uint128 reserveA, uint128 reserveB) internal view {
    IDexterity.Pool memory pool = dex.getPool(address(tokenA), address(tokenB));

    (uint128 poolReserveA, uint128 poolReserveB) = pool.firstToken == address(tokenA)
      ? (pool.firstReserve, pool.secondReserve)
      : (pool.secondReserve, pool.firstReserve);

    assertEq(poolReserveB, reserveB);
    assertEq(poolReserveA, reserveA);
  }
}

contract DeployTests is DexterityTests {
  function test_deploy_creatorIsSet() public view {
    assertEq(dex.creator(), address(this));
  }
}

contract DepositTests is DexterityTests {
  function test_deposit_fails_withZeroAmount() public {
    vm.expectRevert(IDexterity.DepositInvalidAmount.selector);
    depositAB(0, 0);

    vm.expectRevert(IDexterity.DepositInvalidAmount.selector);
    depositAB(1000, 0);

    vm.expectRevert(IDexterity.DepositInvalidAmount.selector);
    depositAB(0, 1000);
  }

  function test_deposit_fails_withZeroAddressForToken() public {
    vm.expectRevert(IDexterity.DepositZeroAddress.selector);
    dex.deposit(address(0), address(0), 0, 0);

    vm.expectRevert(IDexterity.DepositZeroAddress.selector);
    dex.deposit(address(tokenA), address(0), 0, 0);

    vm.expectRevert(IDexterity.DepositZeroAddress.selector);
    dex.deposit(address(0), address(tokenA), 0, 0);
  }

  function test_deposit_fails_withSameToken() public {
    vm.expectRevert(IDexterity.DepositSameToken.selector);
    dex.deposit(address(tokenA), address(tokenA), 1, 2);
  }

  function test_deposit_fails_forOverflowingAmounts() public {
    uint128 uint128max = type(uint128).max;

    tokenA.mintFor(alice, uint256(uint128max) * 2);
    tokenB.mintFor(alice, uint256(uint128max) * 2);

    vm.startPrank(alice);
    tokenA.approve(address(dex), uint256(uint128max) * 2);
    tokenB.approve(address(dex), uint256(uint128max) * 2);

    depositAB(uint128max - 1, uint128max - 1);

    vm.expectRevert(IDexterity.DepositOverflowing.selector);
    depositAB(uint128max, 1);

    vm.expectRevert(IDexterity.DepositOverflowing.selector);
    depositAB(1, uint128max);

    vm.stopPrank();
  }

  function test_deposit_succeeds_andEmitPoolCreatedOnFirstDeposit() public {
    tokenA.mintFor(alice, 3);
    tokenB.mintFor(alice, 6);

    vm.startPrank(alice);

    IERC20(tokenA).approve(address(dex), 3);
    IERC20(tokenB).approve(address(dex), 6);

    expectEmitPoolCreatedAB();
    depositAB(2, 5);

    vm.stopPrank();

    assertPoolReserveABEq(2, 5);
  }

  function test_deposit_succeeds_withCorrectAmounts() public {
    tokenA.mintFor(alice, 3);
    tokenB.mintFor(alice, 6);

    vm.startPrank(alice);

    IERC20(tokenA).approve(address(dex), 3);
    IERC20(tokenB).approve(address(dex), 6);

    vm.expectEmit();
    emit IDexterity.Deposited(address(tokenA), address(tokenB), 1, 2);
    depositAB(1, 2);

    vm.expectEmit();
    emit IDexterity.Deposited(address(tokenA), address(tokenB), 2, 4);
    depositAB(2, 4);

    assertEq(tokenA.balanceOf(alice), 0);
    assertEq(tokenB.balanceOf(alice), 0);

    assertPoolReserveABEq(3, 6);

    vm.stopPrank();
  }
}

contract WithdrawTests is DexterityTests {
  function test_withdraw_fails_whenSenderHasNotEnoughShares() public {
    vm.expectRevert(IDexterity.WithdrawNotEnoughShares.selector);
    dex.withdraw(address(tokenA), address(tokenB), 1);

    vm.startPrank(alice);
    vm.expectRevert(IDexterity.WithdrawNotEnoughShares.selector);
    withdrawAB(1);
    vm.stopPrank();

    tokenA.mintFor(alice, 2);
    tokenB.mintFor(alice, 2);

    vm.startPrank(alice);
    vm.expectRevert(IDexterity.WithdrawNotEnoughShares.selector);
    withdrawAB(3);
    vm.stopPrank();
  }

  function test_withdraw_fails_withZeroShare() public {
    vm.expectRevert(IDexterity.WithdrawNotEnoughShares.selector);
    withdrawAB(0);
  }

  function test_withdraw_succeeds_whenSenderHasEnoughShares() public {
    tokenA.mintFor(alice, 100_000);
    tokenB.mintFor(alice, 1000);

    vm.startPrank(alice);
    tokenA.approve(address(dex), 100_000);
    tokenB.approve(address(dex), 1000);

    depositAB(100_000, 1000);

    withdrawAB(7000);
    withdrawAB(1000);

    vm.expectRevert(IDexterity.WithdrawNotEnoughShares.selector);
    withdrawAB(2001);
    vm.stopPrank();

    assertEq(tokenA.balanceOf(alice), 80_000);
    assertEq(tokenB.balanceOf(alice), 800);
    assertEq(tokenA.balanceOf(address(dex)), 20_000);
    assertEq(tokenB.balanceOf(address(dex)), 200);

    assertPoolReserveABEq(20_000, 200);
  }

  function test_withdraw_succeeeds_withDifferentHolders() public {
    tokenA.mintFor(alice, 10_000);
    tokenB.mintFor(alice, 100);

    tokenA.mintFor(bob, 10_000);
    tokenB.mintFor(bob, 100);

    vm.startPrank(alice);
    tokenA.approve(address(dex), 5000);
    tokenB.approve(address(dex), 100);

    depositAB(5000, 50);
    withdrawAB(500);
    vm.stopPrank();

    vm.startPrank(bob);
    tokenA.approve(address(dex), 5000);
    tokenB.approve(address(dex), 50);

    depositAB(5000, 50);
    withdrawAB(500);
    vm.stopPrank();

    assertEq(tokenA.balanceOf(alice), 10_000);
    assertEq(tokenB.balanceOf(alice), 100);
    assertEq(tokenA.balanceOf(bob), 10_000);
    assertEq(tokenB.balanceOf(bob), 100);
    assertEq(tokenA.balanceOf(address(dex)), 0);
    assertEq(tokenB.balanceOf(address(dex)), 0);

    assertPoolReserveABEq(0, 0);
  }
}

contract SwapTests is DexterityTests {
  function test_swap_fails_withSameToken() public {
    vm.expectRevert(IDexterity.SwapSameToken.selector);
    dex.swap(address(tokenA), 0, address(tokenA));
  }

  function test_swap_fails_ifZeroAmount() public {
    vm.expectRevert(IDexterity.SwapInvalidAmount.selector);
    dex.swap(address(tokenA), 0, address(tokenB));

    vm.expectRevert(IDexterity.SwapInvalidAmount.selector);
    dex.swap(address(tokenB), 0, address(tokenA));
  }

  function test_swap_fails_forPoolWithInsufficientLiquidity() public {
    mintTokenABFor(alice, 1, 1);
    holderDepositAB(alice, 1, 1);

    vm.expectRevert(IDexterity.SwapInsufficientLiquidity.selector);
    dex.swap(address(tokenA), 2, address(tokenB));
  }

  function test_swap_succeeds_withSmallVolume() public {
    mintTokenABFor({ holder: alice, amountA: 8000, amountB: 800_000 });
    mintTokenABFor({ holder: bob, amountA: 2000, amountB: 200_000 });

    holderDepositAB({ holder: alice, amountA: 8000, amountB: 800_000 }); // 80k shares for alice
    holderDepositAB({ holder: bob, amountA: 2000, amountB: 200_000 }); // 20k shares for bob

    mintTokenABFor({ holder: chuck, amountA: 0, amountB: 100_000 }); // swapper, hardcoded fee model is 0.03%

    uint256 oldK = getPoolABInvariant();

    vm.startPrank(chuck);

    tokenB.approve(address(dex), 100_000);

    vm.expectEmit();
    emit IDexterity.Swapped(chuck, address(tokenB), address(tokenA), 100_000, 906);
    dex.swap({ sourceToken: address(tokenB), amount: 100_000, destinationToken: address(tokenA) });

    vm.stopPrank();

    uint256 newK = getPoolABInvariant();

    assertEq(906, tokenA.balanceOf(chuck));
    assertEq(0, tokenB.balanceOf(chuck));
    assertEq(9094, tokenA.balanceOf(address(dex)));
    assertEq(1_100_000, tokenB.balanceOf(address(dex)));
    assertPoolReserveABEq(9094, 1_100_000);
    assertGe(newK, oldK);
  }

  function test_swap_forwardToUniswapv2_withUnsupportedPairAndFails() public {
    vm.makePersistent(address(dex));

    vm.createSelectFork(vm.envString("MAINNET_URL"));
    vm.rollFork(vm.envUint("MAINNET_FORK_BLOCK"));

    vm.expectRevert(IDexterity.SwapUniswapForwardFailure.selector);
    dex.swap(address(tokenA), 1000, address(tokenB));

    vm.revokePersistent(address(dex));
  }
}
