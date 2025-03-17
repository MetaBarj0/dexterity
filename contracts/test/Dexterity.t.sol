// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { Test, console } from "forge-std/Test.sol";

contract DexterityTest is Test {
  Dexterity public dexterity;
  address public constant uniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

  function setUp() public {
    string memory mainnetRpcUrl = vm.rpcUrl("mainnet");
    uint256 mainnetFork = vm.createSelectFork(mainnetRpcUrl, 22_066_155);

    dexterity = new Dexterity();
  }

  function test_read_uniswapv2_succeeds() public {
    (bool success, bytes memory data) = uniswapV2Factory.call(abi.encodeWithSignature("allPairsLength()"));

    uint256 count;
    assembly {
      count := mload(add(data, 0x20))
    }

    assertTrue(success);
    console.log(count);
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
