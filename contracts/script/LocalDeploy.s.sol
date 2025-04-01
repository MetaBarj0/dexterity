// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";

import { Script, console } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

contract SepoliaDeployScript is Script {
  function setUp() public { }

  function run() public {
    vm.startBroadcast();

    new Dexterity();

    vm.stopBroadcast();
  }
}
