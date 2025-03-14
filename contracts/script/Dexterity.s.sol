// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { Script, console } from "forge-std/Script.sol";

contract DexterityScript is Script {
  Dexterity public dexterity;

  function setUp() public { }

  function run() public {
    vm.startBroadcast();

    dexterity = new Dexterity();

    vm.stopBroadcast();
  }
}
