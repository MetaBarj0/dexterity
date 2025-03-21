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

  function createERC20OnlyPair(address token0, address token1) external override returns (uint256 pairId) {
    require(address(token0) != address(0) && address(token1) != address(0), CreateERC20OnlyPairZeroAddress());
    require(address(token0) != address(token1), CreateERC20OnlyPairSameAddress());

    (address lesserToken, address greaterToken) = token0 < token1 ? (token0, token1) : (token1, token0);

    pairId = _computeERC20OnlyPairId(lesserToken, greaterToken);

    ERC20Pair storage pair = erc20Pairs[pairId];

    require(pair.token0 == address(0) && pair.token1 == address(0), CreateERC20OnlyPairAlreadyExists());

    pair.token0 = lesserToken;
    pair.token1 = greaterToken;

    emit ERC20OnlyPairCreated(token0, token1, pairId);
  }

  function createERC20EtherPair(address token) external override returns (uint256 pairId) {
    require(token != address(0), CreateERC20EtherPairZeroAddress());

    pairId = _computeERC20EtherPairId(token);

    require(erc20EtherPairs[pairId] == address(0), CreateERC20EtherPairAlreadyExists());

    erc20EtherPairs[pairId] = token;

    emit ERC20EtherPairCreated(address(token), pairId);
  }

  function depositERC20Only(address token0, address token1, uint256 token0Amount, uint256 token1Amount)
    external
    override
  {
    require(token0Amount > 0 && token1Amount > 0, DepositERC20OnlyInsufficientAmount());
    require(erc20Pairs[_computeERC20OnlyPairId(token0, token1)].token0 != address(0), DepositERC20OnlyUnhandledToken());
  }

  function _computeERC20OnlyPairId(address token0, address token1) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(token0, token1)));
  }

  function _computeERC20EtherPairId(address token) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(token)));
  }
}
