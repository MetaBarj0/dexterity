// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { Dexterity } from "../src/Dexterity.sol";
import { IDexterity } from "../src/interface/IDexterity.sol";
import { TokenA } from "../test/ERC20/TokenA.sol";
import { TokenB } from "../test/ERC20/TokenB.sol";
import { TokenC } from "../test/ERC20/TokenC.sol";

import { Script, console } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

contract DepositAndSwapScript is Script {
  IDexterity dex;

  mapping(string who => Vm.Wallet) private wallets_;

  TokenA private tokenA_;
  TokenB private tokenB_;
  TokenC private tokenC_;

  function setUp() public {
    setupWallets_();
    deployContracts_();
  }

  function run() public {
    doDeposits_();
  }

  function doDeposits_() private {
    provisionHolders_();
    makeDeposit_("alice");
    makeDeposit_("bob");
  }

  function setupWallets_() private {
    setupWallet_("alice");
    setupWallet_("bob");
    setupWallet_("chuck");
  }

  function setupWallet_(string memory who) private {
    (, uint256 pkey) = makeAddrAndKey(who);
    Vm.Wallet memory wallet = vm.createWallet(pkey);

    vm.startBroadcast();
    payable(wallet.addr).transfer(1 ether);
    vm.stopBroadcast();

    wallets_[who] = wallet;
  }

  function deployContracts_() private {
    vm.startBroadcast();

    dex = new Dexterity();

    tokenA_ = new TokenA();
    tokenB_ = new TokenB();
    tokenC_ = new TokenC();

    vm.stopBroadcast();
  }

  function provisionHolders_() private {
    uint128 sAmount = 10 ** 18 * 10_000;
    uint128 mAmount = 10 ** 18 * 1_000_000;
    uint128 lAmount = 10 ** 18 * 100_000_000;

    Vm.Wallet storage alice = wallets_["alice"];
    Vm.Wallet storage bob = wallets_["bob"];

    vm.startBroadcast();

    tokenA_.mintFor(alice.addr, 2 * sAmount);
    tokenB_.mintFor(alice.addr, 2 * mAmount);
    tokenC_.mintFor(alice.addr, 2 * lAmount);

    tokenA_.mintFor(bob.addr, sAmount);
    tokenB_.mintFor(bob.addr, mAmount);
    tokenC_.mintFor(bob.addr, lAmount);

    vm.stopBroadcast();
  }

  function makeDeposit_(string memory who) private {
    Vm.Wallet storage wallet = wallets_[who];

    vm.startBroadcast(wallet.privateKey);

    tokenA_.approve(address(dex), uint128(tokenA_.balanceOf(wallet.addr)));
    tokenB_.approve(address(dex), uint128(tokenB_.balanceOf(wallet.addr)));
    tokenC_.approve(address(dex), uint128(tokenC_.balanceOf(wallet.addr)));

    dex.deposit(
      address(tokenA_),
      address(tokenB_),
      uint128(tokenA_.balanceOf(wallet.addr)),
      uint128(tokenB_.balanceOf(wallet.addr) / 2)
    );

    dex.deposit(
      address(tokenC_),
      address(tokenB_),
      uint128(tokenC_.balanceOf(wallet.addr)),
      uint128(tokenB_.balanceOf(wallet.addr) / 2)
    );

    vm.stopBroadcast();
  }
}
