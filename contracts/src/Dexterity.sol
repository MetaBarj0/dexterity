// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDexterity } from "./interfaces/IDexterity.sol";

contract Dexterity is IDexterity {
  address public immutable creator;

  constructor() {
    creator = msg.sender;
  }
}
