// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../providers/MortgageProvider.sol";

contract MortgagePool is ReentrancyGuard {
    address public factoryController;

    uint256 public totalBalance;
    mapping(address => uint256) public mortgageLiquidity;
    mapping(address => uint256) public mortgageLiquidityPercentage;

    constructor(address _factoryController) {
        factoryController = _factoryController;
    }

    modifier onlyFactoryController() {
        require(msg.sender == factoryController, "Only controller can call this function");
        _;
    }

    modifier onlyMortgageProvider() {
        require(msg.sender == address(this), "Only mortgage provider can call this function");
        _;
    }

    // fallback and receive
    fallback() external payable {
        provideMortgageLiquidity();
    }
    receive() external payable {
        provideMortgageLiquidity();
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function provideMortgageLiquidity() public nonReentrant payable {
        require(msg.value > 0, "Must send ether to provide liquidity");

        totalBalance += msg.value;
        mortgageLiquidity[msg.sender] += msg.value;
        uint256 liquidityPercentage = (mortgageLiquidity[msg.sender] / totalBalance) * 100; // used to payout interest
        mortgageLiquidityPercentage[msg.sender] = liquidityPercentage;
    }
}
