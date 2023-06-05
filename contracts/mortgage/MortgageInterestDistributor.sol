// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IMortgagePool.sol";

contract MortgageInterestDistributor is ReentrancyGuard {
    error OnlySystem();

    MortgagePoolInterface public mortgagePool;

    address private _system;

    mapping(address => uint256) public mortgageLiquidityPercentage;

    constructor(address _mortgagePool, address system) {
        mortgagePool = MortgagePoolInterface(_mortgagePool);
        _system = system;
    }

    modifier onlySystem() {
        if (msg.sender != system)
            revert OnlySystem();
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
        uint mortgageProvidersLength = mortgageProviders.length;
        for (uint i = 0; i < mortgageProvidersLength; ++i) {
            uint providerBalance = mortgagePool.getMortgageLiquidityAmount(mortgageProviders[i]);
            mortgageLiquidityPercentage[mortgageProviders[i]] = (providerBalance * 100) / calcBalance;
        }
    }
}
