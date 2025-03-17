// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";

import { Script, console } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

contract DexterityScript is Script {
  function setUp() public { }

  function run() public {
    uint256 pk = vm.envUint("PRIVATE_KEY");
    Vm.Wallet memory wallet = vm.createWallet(pk);

    vm.startBroadcast(wallet.privateKey);

    Dexterity dexterity = new Dexterity();

    vm.stopBroadcast();
  }
}
