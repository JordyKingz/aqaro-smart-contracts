pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/token/AqaroToken.sol";
import "../../contracts/token/staking/StakeVault.sol";
import "../../contracts/token/sale/EarlySale.sol";
import "../../contracts/token/staking/StakeVaultDistributor.sol";

contract StakeVaultTest is Test {
    error OnlyFactoryController();
    error OnlyFeeDistributor();
    error StakingPeriodNotEnded();
    error StakingPeriodHasEnded();
    error AmountIsZero();
    error InsufficientBalance();
    error NoAllowance();
    error AddressCannotBeZero();
    error CannotRecoverAQRToken();

    address public factoryController = address(0xABCD);
    AqaroToken public aqaroToken;
    AqaroEarlySale public earlySale;
    StakeVault public stakeVault;
    StakeVaultDistributor public stakeVaultDistributor;

    address public alice = address(0x1234);
    address public bob = address(0x5678);
    address public charlie = address(0x9ABC);

    // todo: refactor?
    uint public periodFinish;
    uint public rewardRate;
    uint public rewardsDuration;
    uint public rewardsForDuration;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint public lastTimeRewardApplicable;
    uint public rewardPerToken;
    uint public totalSupply;

    function setUp() public {
        aqaroToken = new AqaroToken(factoryController);
        stakeVault = new StakeVault(address(aqaroToken), factoryController);
        earlySale = new AqaroEarlySale(factoryController, address(aqaroToken));

        stakeVaultDistributor = new StakeVaultDistributor(address(aqaroToken), factoryController, address(stakeVault));

        vm.startPrank(factoryController);
        aqaroToken.transfer(address(earlySale), 3_000_000e18); // 3M

        // set fee distributor
        stakeVault.setRewardDistributor(address(stakeVaultDistributor));
        vm.stopPrank();
    }

    function test_periodFinish() public {
        periodFinish = stakeVault.periodFinish();
        assertEq(periodFinish, (block.timestamp + 60 days));
    }

    function test_rewardRate() public {
        rewardRate = stakeVault.rewardRate();
        assertEq(rewardRate, 0);
    }

    function test_rewardsDuration() public {
        rewardsDuration = stakeVault.rewardsDuration();
        assertEq(rewardsDuration, 1 days);
    }

    function test_lastUpdateTime() public {
        lastUpdateTime = stakeVault.lastUpdateTime();
        assertEq(lastUpdateTime, 0);
    }

    function test_rewardPerTokenStored() public {
        rewardPerTokenStored = stakeVault.rewardPerTokenStored();
        assertEq(rewardPerTokenStored, 0);
    }

    function test_lastTimeRewardApplicable() public {
        lastTimeRewardApplicable = stakeVault.lastTimeRewardApplicable();
        assertEq(lastTimeRewardApplicable, block.timestamp);
    }

    function test_rewardPerToken() public {
        rewardPerToken = stakeVault.rewardPerToken();
        assertEq(rewardPerToken, 0);
    }

    function test_getRewardForDuration() public {
        rewardsForDuration = stakeVault.getRewardForDuration();
        assertEq(rewardsForDuration, 0);
    }

    function test_totalSupply() public {
        totalSupply = stakeVault.totalSupply();
        assertEq(totalSupply, 0);
    }
}
