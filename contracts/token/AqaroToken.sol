// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IAqaroToken.sol";

contract AqaroToken is AqaroTokenInterface, ERC20 {
    constructor(address factoryController) ERC20("Aqaro", "AQRO") {
        _mint(factoryController, 100_000_000e18);
    }
}
