// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { IDexterity } from "../src/interface/IDexterity.sol";

import { TokenA } from "./ERC20/TokenA.sol";
import { TokenB } from "./ERC20/TokenB.sol";
import { TokenC } from "./ERC20/TokenC.sol";
import { Test, console } from "forge-std/Test.sol";

contract DexterityDeployTests is Test {
  Dexterity dex;

  function setUp() public {
    dex = new Dexterity();
  }

  function test_deploy_creatorIsSet() public view {
    assertEq(dex.creator(), address(this));
  }
}

contract DexterityTests is Test {
  Dexterity dex;
  TokenA tokenA;
  TokenB tokenB;
  TokenC tokenC;
  address tokenAAddress;
  address tokenBAddress;
  address tokenCAddress;

  function setUp() public {
    dex = new Dexterity();
    tokenA = new TokenA();
    tokenB = new TokenB();
    tokenC = new TokenC();
    tokenAAddress = address(tokenA);
    tokenBAddress = address(tokenB);
    tokenCAddress = address(tokenC);
  }

  function test_createERC20Pair_fails_WithZeroTokenAddresses() public {
    vm.expectRevert(IDexterity.CreateERC20OnlyPairZeroAddress.selector);

    dex.createERC20OnlyPair(address(0), address(0));
  }

  function test_createERC20Pair_fails_WithSameTokenAddress() public {
    vm.expectRevert(IDexterity.CreateERC20OnlyPairSameAddress.selector);

    dex.createERC20OnlyPair(tokenAAddress, tokenAAddress);
  }

  function test_createERC20Pair_returnsPairId_WithValidTokenAddresses() public {
    uint256 pairId = dex.createERC20OnlyPair(tokenAAddress, tokenBAddress);

    assertNotEq(uint256(0), pairId);
  }

  function test_createERC20Pair_fails_whenPairAlreadyExists() public {
    dex.createERC20OnlyPair(tokenAAddress, tokenBAddress);

    vm.expectRevert(IDexterity.CreateERC20OnlyPairAlreadyExists.selector);
    dex.createERC20OnlyPair(tokenBAddress, tokenAAddress);
  }

  function test_createERC20EtherPair_fails_withZeroTokenAddress() public {
    vm.expectRevert(IDexterity.CreateERC20EtherPairZeroAddress.selector);
    dex.createERC20EtherPair(address(0));
  }

  function test_createERC20EtherPair_returnsPairId_withValidTokenAddress() public {
    uint256 pairId = dex.createERC20EtherPair(tokenAAddress);

    assertNotEq(uint256(0), pairId);
  }

  function test_createERC20EtherPair_fails_whenPairAlreadyExists() public {
    dex.createERC20EtherPair(tokenAAddress);

    vm.expectRevert(IDexterity.CreateERC20EtherPairAlreadyExists.selector);
    dex.createERC20EtherPair(tokenAAddress);
  }

  function test_createERC20OnlyPair_emitsERC20OnlyPairCreated_withValidPair() public {
    uint256 pairId = uint256(keccak256(abi.encodePacked(tokenAAddress, tokenBAddress)));

    vm.expectEmit();
    emit IDexterity.ERC20OnlyPairCreated(tokenAAddress, tokenBAddress, pairId);

    dex.createERC20OnlyPair(tokenAAddress, tokenBAddress);
  }

  function test_createERC20EtherPair_emitsERC20EtherPairCreated_withValidPair() public {
    uint256 pairId = uint256(keccak256(abi.encodePacked(tokenAAddress)));

    vm.expectEmit();
    emit IDexterity.ERC20EtherPairCreated(tokenAAddress, pairId);

    dex.createERC20EtherPair(tokenAAddress);
  }

  function test_depositERC20Only_fails_withUnhandledToken() public {
    dex.createERC20OnlyPair(tokenAAddress, tokenBAddress);

    vm.expectRevert(IDexterity.DepositERC20OnlyUnhandledToken.selector);
    dex.depositERC20Only(address(0), address(0), uint256(1), uint256(2));
  }

  function test_depositERC20Only_fails_withInsufficientAmount() public {
    dex.createERC20OnlyPair(tokenAAddress, tokenBAddress);

    vm.expectRevert(IDexterity.DepositERC20OnlyInsufficientAmount.selector);
    dex.depositERC20Only(tokenAAddress, tokenBAddress, uint256(0), uint256(0));
  }

  // TODO: fuzzing here
  function test_depositERC20Only_givesSharesDependingOnTheAmount() public {
    dex.createERC20OnlyPair(tokenAAddress, tokenBAddress);

    uint256 shares;

    shares = dex.depositERC20Only(tokenAAddress, tokenBAddress, uint256(1), uint256(1));
    assertEqUint(shares, 1);

    shares = dex.depositERC20Only(tokenAAddress, tokenBAddress, uint256(90), uint256(40));
    assertEqUint(shares, 60);

    shares = dex.depositERC20Only(tokenAAddress, tokenBAddress, uint256(10), uint256(1000));
    assertEqUint(shares, 100);

    shares = dex.depositERC20Only(tokenAAddress, tokenBAddress, uint256(400), uint256(4_000_000));
    assertEqUint(shares, 40_000);
  }

  function test_withdrawERC20Only_fails_withUnhandledToken() public {
    dex.createERC20OnlyPair(tokenAAddress, tokenBAddress);

    vm.expectRevert(IDexterity.WithdrawERC20OnlyUnhandledToken.selector);
    dex.withdrawERC20Only(address(0), address(0), uint256(1), uint256(1), uint256(1));
  }

  function test_withdrawERC20Only_fails_withInsufficientShares() public {
    dex.createERC20OnlyPair(tokenAAddress, tokenBAddress);
    dex.depositERC20Only(tokenAAddress, tokenBAddress, uint256(100), uint256(10_000));

    vm.expectRevert(IDexterity.WithdrawERC20OnlyInsufficientShares.selector);
    dex.withdrawERC20Only(tokenBAddress, tokenAAddress, uint256(2_000_000), uint256(0), uint256(0));
  }

  function test_withdrawERC20Only_fails_withMinAmountsTooHigh() public {
    dex.createERC20OnlyPair(tokenAAddress, tokenBAddress);
    dex.depositERC20Only(tokenAAddress, tokenBAddress, uint256(100), uint256(10_000));

    vm.expectRevert(
      abi.encodeWithSelector(IDexterity.WithdrawERC20OnlyMinAmountTooHigh.selector, tokenAAddress, uint256(100))
    );
    dex.withdrawERC20Only(tokenBAddress, tokenAAddress, uint256(1_000_000), uint256(0), uint256(200));
  }
}
