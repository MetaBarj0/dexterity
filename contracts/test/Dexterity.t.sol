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
    vm.expectRevert(IDexterity.CreateERC20OnlyPairZeroAddress.selector);

    dex.createERC20OnlyPair(address(0), address(0));
  }

  function test_createERC20Pair_returnsPairId_WithValidTokenAddresses() public {
    uint256 pairId = dex.createERC20OnlyPair(address(tokenA), address(tokenB));

    assertNotEq(uint256(0), pairId);
  }

  function test_createERC20Pair_fails_whenPairAlreadyExists() public {
    dex.createERC20OnlyPair(address(tokenA), address(tokenB));

    vm.expectRevert(IDexterity.CreateERC20OnlyPairAlreadyExists.selector);
    dex.createERC20OnlyPair(address(tokenB), address(tokenA));
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

  function test_createERC20OnlyPair_emitsERC20OnlyPairCreated_withValidPair() public {
    uint256 pairId = uint256(keccak256(abi.encodePacked(address(tokenA), address(tokenB))));

    vm.expectEmit();
    emit IDexterity.ERC20OnlyPairCreated(address(tokenA), address(tokenB), pairId);

    dex.createERC20OnlyPair(address(tokenA), address(tokenB));
  }

  function test_createERC20EtherPair_emitsERC20EtherPairCreated_withValidPair() public {
    uint256 pairId = uint256(keccak256(abi.encodePacked(address(tokenA))));

    vm.expectEmit();
    emit IDexterity.ERC20EtherPairCreated(address(tokenA), pairId);

    dex.createERC20EtherPair(address(tokenA));
  }
}
