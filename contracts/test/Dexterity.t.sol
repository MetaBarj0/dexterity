// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { IDexterity } from "../src/interfaces/IDexterity.sol";

import { TokenA } from "./ERC20/TokenA.sol";
import { TokenB } from "./ERC20/TokenB.sol";
import { Test, console } from "forge-std/Test.sol";

contract DexterityTests is Test {
  Dexterity public dex;

  function setUp() public {
    dex = new Dexterity();
  }

  function test_deploy_creatorIsSet() public view {
    assertEq(dex.creator(), address(this));
  }

  function test_createPair_fails_WithZeroTokenAddresses() public {
    vm.expectRevert(IDexterity.CreatePairZeroAddress.selector);

    dex.createPair(address(0), address(0));
  }

  function test_createPair_returnsPairId_WithValidTokenAddresses() public {
    TokenA tokenA = new TokenA();
    TokenB tokenB = new TokenB();

    uint256 pairId = dex.createPair(address(tokenA), address(tokenB));

    assertNotEq(uint256(0), pairId);
  }

  function test_createPair_fails_whenPairAlreadyExists() public {
    TokenA tokenA = new TokenA();
    TokenB tokenB = new TokenB();

    dex.createPair(address(tokenA), address(tokenB));

    vm.expectRevert(IDexterity.CreatePairAlreadyExists.selector);
    dex.createPair(address(tokenB), address(tokenA));
  }
}
