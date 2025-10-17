// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Dexterity } from "../src/Dexterity.sol";
import { IDexterity } from "../src/interface/IDexterity.sol";
import { TokenA } from "../test/ERC20/TokenA.sol";
import { TokenB } from "../test/ERC20/TokenB.sol";
import { TokenC } from "../test/ERC20/TokenC.sol";

import { Script, console } from "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

contract DepositAndSwapScript is Script {
  struct Wallet {
    uint256 pkey;
    address addr;
  }

  IDexterity dex;

  mapping(string who => Wallet) private wallets_;

  TokenA private tokenA_;
  TokenB private tokenB_;
  TokenC private tokenC_;

  function setUp() public {
    setupWallets_();
    deployContracts_();
  }

  function run() public {
    doDeposits_();
    doSwaps_();
  }

  function doDeposits_() private {
    provisionUser_("alice");
    provisionUser_("bob");
    provisionUser_("chuck");

    makeDeposit_("alice");
    makeDeposit_("bob");
  }

  function doSwaps_() private {
    Wallet storage chuck = wallets_["chuck"];

    vm.startBroadcast(chuck.pkey);

    tokenB_.approve(address(dex), tokenB_.balanceOf(chuck.addr));
    dex.swapOut(address(tokenA_), 1000, address(tokenB_));
    tokenB_.approve(address(dex), 0);

    vm.stopBroadcast();

    vm.startBroadcast(chuck.pkey);

    tokenC_.approve(address(dex), tokenC_.balanceOf(chuck.addr));
    dex.swapIn(address(tokenC_), 10_000, address(tokenB_));
    tokenC_.approve(address(dex), 0);

    vm.stopBroadcast();
  }

  function setupWallets_() private {
    setupWallet_("alice", "TEST_PRIVATE_KEY_01");
    setupWallet_("bob", "TEST_PRIVATE_KEY_02");
    setupWallet_("chuck", "TEST_PRIVATE_KEY_03");
  }

  function setupWallet_(string memory who, string memory env) private {
    Wallet memory w;
    w.pkey = uint256(vm.envBytes32(env));
    w.addr = vm.addr(w.pkey);
    wallets_[who] = w;
  }

  function deployContracts_() private {
    vm.startBroadcast();

    dex = new Dexterity();

    tokenA_ = new TokenA();
    tokenB_ = new TokenB();
    tokenC_ = new TokenC();

    vm.stopBroadcast();
  }

  function provisionUser_(string memory who) private {
    uint128 sAmount = 10 ** 18 * 10_000;
    uint128 mAmount = 10 ** 18 * 1_000_000;
    uint128 lAmount = 10 ** 18 * 100_000_000;

    Wallet storage holder = wallets_[who];

    vm.startBroadcast();

    tokenA_.mintFor(holder.addr, 2 * sAmount);
    tokenB_.mintFor(holder.addr, 2 * mAmount);
    tokenC_.mintFor(holder.addr, 2 * lAmount);

    vm.stopBroadcast();
  }

  function makeDeposit_(string memory who) private {
    Wallet storage wallet = wallets_[who];

    vm.startBroadcast(wallet.pkey);

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
