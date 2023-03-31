// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IMortgagePool.sol";

contract MortgageInterestDistributor is ReentrancyGuard {
    MortgagePoolInterface public mortgagePool;

    address private _system;

    mapping(address => uint256) public mortgageLiquidityPercentage;

    constructor(address _mortgagePool, address system) {
        mortgagePool = MortgagePoolInterface(_mortgagePool);
        _system = system;
    }

    modifier onlySystem() {
        require(msg.sender == _system, "Only system can call this function");
        _;
    }

    // calculation on how much every mortgage provider should get
    // based on their percentage of the total mortgage pool balance
    // costs a lot of gas with more providers, so extract these costs from the total balance
    // will be used to payout mortgage providers
    function calculateMortgageLiquidityProvidersPercentages(uint estimatedGas) public onlySystem {
        address[] memory mortgageProviders = mortgagePool.getMortgageProviders();

        uint totalBalance = mortgagePool.contractBalance();
        // subtract estimated gas cost from total balance
        uint calcBalance = totalBalance - estimatedGas;
        for (uint i = 0; i < mortgageProviders.length; ++i) {
            uint providerBalance = mortgagePool.getMortgageLiquidityAmount(mortgageProviders[i]);
            mortgageLiquidityPercentage[mortgageProviders[i]] = (providerBalance / calcBalance) * 100;
        }
    }
}
