// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { Test, console } from "forge-std/Test.sol";

contract DexterityTest is Test {
  Dexterity public dexterity;

  function setUp() public {
    dexterity = new Dexterity();
  }

  function test_failingTest() public pure {
    console.log("A failing test...");

    assertEq(uint256(123), uint256(456));
  }

  /*
   * function testFuzz_fuzzingExample()public{
   * ...
   * }
  */
}
