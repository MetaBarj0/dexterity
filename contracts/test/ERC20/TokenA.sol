// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20 {
  address private owner_;
  bool approveMustFail_;

  error Unauthorized();

  constructor() ERC20("Token A", "TKA") {
    owner_ = msg.sender;
  }

  function owner() public view returns (address) {
    return owner_;
  }

  function decimals() public pure override returns (uint8) {
    return 18;
  }

  function approve(address spender, uint256 value) public override returns (bool) {
    if (approveMustFail_) return false;

    return super.approve(spender, value);
  }

  function mintFor(address to, uint256 amount) external {
    require(msg.sender == owner_, Unauthorized());

    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external {
    require(msg.sender == owner_, Unauthorized());

    if (amount > totalSupply()) amount = totalSupply();

    _burn(from, amount);
  }

  function setApproveToFail(bool value) external {
    approveMustFail_ = value;
  }
}
