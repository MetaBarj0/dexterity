// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { Script, console } from "forge-std/Script.sol";

contract DexterityScript is Script {
  function setUp() public { }

  function run() public {
    uint256 pk = vm.envUint("PRIVATE_KEY");

    vm.startBroadcast(pk);

    Dexterity dexterity = new Dexterity();

    vm.stopBroadcast();
  }
}
