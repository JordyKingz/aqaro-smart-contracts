// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/IAqaroToken.sol";
import "../../interfaces/IStakeVault.sol";

contract StakeVaultDistributor is ReentrancyGuard {
    event Distributed(uint256 amount);

    address public factoryController;
    AqaroTokenInterface public token;
    StakeVaultInterface public stakeVault;

    uint256 public distributionPeriod = 60 days;
    uint256 public interval = 1 days;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;

    constructor(address _token, address _factoryController, address _stakeVault) {
        token = AqaroTokenInterface(_token);
        factoryController = _factoryController;

        stakeVault = StakeVaultInterface(_stakeVault);

        periodFinish = block.timestamp + interval;
        rewardRate = 2_000_000 * 10**18 / distributionPeriod;
    }

    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function distribute() external nonReentrant returns (bool success) {
        require(block.timestamp >= periodFinish, "Distribution period not over");
        require(token.balanceOf(address(this)) >= rewardRate, "Not enough tokens to distribute");
        periodFinish = block.timestamp + interval;

        (success) = token.transfer(address(stakeVault), rewardRate);
        require(success, "Error: failed to transfer interest to Gold Stake Vault");
        stakeVault.notifyRewardAmount(rewardRate);

        emit Distributed(rewardRate);
    }
}
