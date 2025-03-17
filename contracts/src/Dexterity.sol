// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IDexterity } from "./interfaces/IDexterity.sol";

contract Dexterity is IDexterity {
  address public immutable creator;

  mapping(uint256 pairId => ERC20Pair pair) public erc20Pairs;
  mapping(uint256 pairId => address token) public erc20EtherPairs;

  constructor() {
    creator = msg.sender;
  }

  function createERC20Pair(address token0, address token1) external override returns (uint256 pairId) {
    require(address(token0) != address(0) && address(token1) != address(0), CreateERC20PairZeroAddress());

    (address lesserToken, address greaterToken) = token0 < token1 ? (token0, token1) : (token1, token0);

    pairId = _computeERC20PairId(lesserToken, greaterToken);

    ERC20Pair storage pair = erc20Pairs[pairId];

    require(pair.token0 == address(0) && pair.token1 == address(0), CreateERC20PairAlreadyExists());

    pair.token0 = lesserToken;
    pair.token1 = greaterToken;
  }

  function createERC20EtherPair(address token) external override returns (uint256 pairId) {
    require(token != address(0), CreateERC20EtherPairZeroAddress());

    pairId = _computeERC20EtherPairId(token);

    require(erc20EtherPairs[pairId] == address(0), CreateERC20EtherPairAlreadyExists());

    erc20EtherPairs[pairId] = token;
  }

  function _computeERC20PairId(address token0, address token1) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(token0, token1)));
  }

  function _computeERC20EtherPairId(address token) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(token)));
  }
}
