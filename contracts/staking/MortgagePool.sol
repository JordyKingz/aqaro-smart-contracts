// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// todo implement nonreentrant

contract MortgagePool {
    uint256 public totalBalance;
    mapping(address => uint256) public mortgageLiquidity;
    mapping(address => uint256) public mortgageLiquidityPercentage;

    constructor() {}

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
