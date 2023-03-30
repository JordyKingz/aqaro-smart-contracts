// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface MortgagePoolInterface {
    function contractBalance() external view returns (uint256);
    function getMortgageProviders() external view returns (address[] memory);
    function getMortgageLiquidityAmount(address _mortgageProvider) external view returns (uint256);
}
