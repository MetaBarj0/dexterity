// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { IDexterity } from "../src/interfaces/IDexterity.sol";

import { TokenA } from "./ERC20/TokenA.sol";
import { TokenB } from "./ERC20/TokenB.sol";
import { Test, console } from "forge-std/Test.sol";

contract DexterityTests is Test {
  Dexterity dex;
  TokenA tokenA;
  TokenB tokenB;
  address tokenAAddress;
  address tokenBAddress;

  function setUp() public {
    dex = new Dexterity();
    tokenA = new TokenA();
    tokenB = new TokenB();
    tokenAAddress = address(tokenA);
    tokenBAddress = address(tokenB);
  }

  function test_deploy_creatorIsSet() public view {
    assertEq(dex.creator(), address(this));
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
}
