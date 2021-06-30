//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GovToken is ERC20 {
  constructor(address minter, uint initialSupply) ERC20("Gov Token", "GOV") {
    _mint(minter, initialSupply);
  }
}