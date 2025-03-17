// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { Test, console } from "forge-std/Test.sol";

contract DexterityTest is Test {
  Dexterity public dex;

  function setUp() public {
    dex = new Dexterity();
  }

  function test_dexterityCreatorIsSetAtDeployTime() public view {
    assertEq(dex.creator(), address(this));
  }

  function test_createPairFailsWithInvalidTokenAddress() public pure { }
}
