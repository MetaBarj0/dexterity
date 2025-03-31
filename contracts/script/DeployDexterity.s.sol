// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";

import { Script, console } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

contract DeployDexterityScript is Script {
  function setUp() public { }

  function run() public {
    // uncomment for local deployment only, using default anvil pk
    // uint256 pk = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    uint256 pk = vm.envUint("PRIVATE_KEY");
    Vm.Wallet memory wallet = vm.createWallet(pk);

    vm.startBroadcast(wallet.privateKey);

    new Dexterity();

    vm.stopBroadcast();
  }
}
