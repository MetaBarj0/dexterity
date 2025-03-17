// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { IDexterity } from "../src/interfaces/IDexterity.sol";

import { TokenA } from "./ERC20/TokenA.sol";
import { TokenB } from "./ERC20/TokenB.sol";
import { Test, console } from "forge-std/Test.sol";

contract DexterityTests is Test {
  Dexterity public dex;
  TokenA tokenA;
  TokenB tokenB;

  function setUp() public {
    dex = new Dexterity();
    tokenA = new TokenA();
    tokenB = new TokenB();
  }

  function test_deploy_creatorIsSet() public view {
    assertEq(dex.creator(), address(this));
  }

  function test_createERC20Pair_fails_WithZeroTokenAddresses() public {
    vm.expectRevert(IDexterity.CreateERC20PairZeroAddress.selector);

    dex.createERC20Pair(address(0), address(0));
  }

  function test_createERC20Pair_returnsPairId_WithValidTokenAddresses() public {
    uint256 pairId = dex.createERC20Pair(address(tokenA), address(tokenB));

    assertNotEq(uint256(0), pairId);
  }

  function test_createERC20Pair_fails_whenPairAlreadyExists() public {
    dex.createERC20Pair(address(tokenA), address(tokenB));

    vm.expectRevert(IDexterity.CreateERC20PairAlreadyExists.selector);
    dex.createERC20Pair(address(tokenB), address(tokenA));
  }

  function test_createERC20EtherPair_fails_withZeroTokenAddress() public {
    vm.expectRevert(IDexterity.CreateERC20EtherPairZeroAddress.selector);
    dex.createERC20EtherPair(address(0));
  }

  function test_createERC20EtherPair_returnsPairId_withValidTokenAddress() public {
    uint256 pairId = dex.createERC20EtherPair(address(tokenA));

    assertNotEq(uint256(0), pairId);
  }

  function test_createERC20EtherPair_fails_whenPairAlreadyExists() public {
    dex.createERC20EtherPair(address(tokenA));

    vm.expectRevert(IDexterity.CreateERC20EtherPairAlreadyExists.selector);
    dex.createERC20EtherPair(address(tokenA));
  }
}
