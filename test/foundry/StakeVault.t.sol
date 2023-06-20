pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/StdUtils.sol";
import "../../contracts/token/AqaroToken.sol";
import "../../contracts/token/staking/StakeVault.sol";
import "../../contracts/token/sale/EarlySale.sol";
import "../../contracts/token/staking/StakeVaultDistributor.sol";

contract StakeVaultTest is Test {
    error OnlyFactoryController();
    error OnlyDistributor();
    error StakingPeriodNotEnded();
    error StakingPeriodHasEnded();
    error AmountIsZero();
    error InsufficientBalance();
    error NoAllowance();
    error AddressCannotBeZero();
    error CannotRecoverAQRToken();
    error PreviousRewardsPeriodNotEnded();

    address public factoryController = address(0xABCD);
    AqaroToken public aqaroToken;
    AqaroEarlySale public earlySale;
    StakeVault public stakeVault;
    StakeVaultDistributor public stakeVaultDistributor;

    AqaroToken public recoverToken;

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
        assertEq(stakeVault.periodFinish(), (block.timestamp + 60 days));
    }

    function test_rewardRate() public {
        assertEq(stakeVault.rewardRate(), 0);
    }

    function test_rewardsDuration() public {
        assertEq(stakeVault.rewardsDuration(), 1 days);
    }

    function test_lastUpdateTime() public {
        assertEq(stakeVault.lastUpdateTime(), 0);
    }

    function test_rewardPerTokenStored() public {
        assertEq(stakeVault.rewardPerTokenStored(), 0);
    }

    function test_lastTimeRewardApplicable() public {
        assertEq(stakeVault.lastTimeRewardApplicable(), block.timestamp);
    }

    function test_rewardPerToken() public {
        assertEq(stakeVault.rewardPerToken(), 0);
    }

    function test_getRewardForDuration() public {
        assertEq(stakeVault.getRewardForDuration(), 0);
    }

    function test_totalSupply() public {
        assertEq(stakeVault.totalSupply(), 0);
    }

    function test_balanceOf() public {
        assertEq(stakeVault.balanceOf(address(this)), 0);
    }

    function test_withdraw_shouldFail_periodNotEnded() public {
        vm.expectRevert(StakingPeriodNotEnded.selector);
        vm.prank(alice);
        stakeVault.withdraw(1000);
    }

    function test_withdraw_shouldFail_amountIsZero() public {
        vm.warp(block.timestamp + 61 days);
        vm.expectRevert(AmountIsZero.selector);
        vm.prank(alice);
        stakeVault.withdraw(0);
    }

    function test_withdraw_shouldFail_insufficientBalance() public {
        vm.warp(block.timestamp + 61 days);
        vm.expectRevert(InsufficientBalance.selector);
        vm.prank(alice);
        stakeVault.withdraw(1000);
    }

    function test_withdraw(uint amount) public {
        vm.assume(amount > 0 && amount <= aqaroToken.balanceOf(factoryController));
        deal(address(aqaroToken), alice, amount);

        vm.startPrank(alice);
        aqaroToken.approve(address(stakeVault), amount);
        stakeVault.stake(amount);

        assertEq(aqaroToken.balanceOf(address(stakeVault)), amount);
        assertEq(stakeVault.balanceOf(alice), amount);

        vm.warp(block.timestamp + 61 days);
        stakeVault.withdraw(amount);

        assertEq(aqaroToken.balanceOf(address(stakeVault)), 0);
        assertEq(stakeVault.balanceOf(alice), 0);
    }

    function test_stake_shouldFail_amountIsZero() public {
        vm.expectRevert(AmountIsZero.selector);
        vm.prank(alice);
        stakeVault.stake(0);
    }

    function test_stake_shouldFail_periodEnded() public {
        vm.warp(block.timestamp + 61 days);
        vm.expectRevert(StakingPeriodHasEnded.selector);
        vm.prank(alice);
        stakeVault.stake(1000);
    }

    function test_stake_shouldFail_noAllowance() public {
        vm.expectRevert(NoAllowance.selector);
        vm.prank(alice);
        stakeVault.stake(1000);
    }

    function test_stake_shouldFail_insufficientBalance(uint amount) public {
        vm.assume(amount > 0 && amount <= aqaroToken.balanceOf(factoryController));
        vm.startPrank(alice);
        aqaroToken.approve(address(stakeVault), amount);

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        stakeVault.stake(amount);
        vm.stopPrank();
    }

    function test_stake(uint amount) public {
        vm.assume(amount > 0 && amount <= aqaroToken.balanceOf(factoryController));
        deal(address(aqaroToken), alice, amount);

        vm.startPrank(alice);
        aqaroToken.approve(address(stakeVault), amount);
        stakeVault.stake(amount);

        assertEq(aqaroToken.balanceOf(address(stakeVault)), amount);
        assertEq(stakeVault.balanceOf(alice), amount);
    }

    // todo implement notifyRewardAmount tests


    function test_notifyRewardAmount_shouldFail_notDistributor() public {
        vm.expectRevert(OnlyDistributor.selector);
        vm.prank(alice);
        stakeVault.notifyRewardAmount(1000);
    }

    function test_notifyRewardAmount_notFinished() public {
        // every day for 60 days we will notifyRewardAmount
        // we will distribute 2M tokens over 60 days
        // 2M / 60 = 33,333.333333333333333333 tokens per day
    }



    function test_recoverERC20_shouldFail_notFactory() public {
        recoverToken = new AqaroToken(factoryController);
        uint amount = 10001e18;
        vm.expectRevert(OnlyFactoryController.selector);
        vm.prank(alice);
        stakeVault.recoverERC20(address(recoverToken), amount);
    }

    function test_recoverERC20_shouldFail_stakeToken() public {
        uint amount = 1000;
        vm.expectRevert(CannotRecoverAQRToken.selector);
        vm.prank(factoryController);
        stakeVault.recoverERC20(address(aqaroToken), amount);
    }

    function test_recoverERC20(uint amount) public {
        recoverToken = new AqaroToken(factoryController);
        vm.assume(amount > 0 && amount <= recoverToken.balanceOf(factoryController));

        // transfer tokens to alice
        vm.prank(factoryController);
        recoverToken.transfer(address(alice), amount);

        // alice transfers tokens to stakeVault
        vm.prank(alice);
        recoverToken.transfer(address(stakeVault), amount);

        uint ownerBalanceBefore = recoverToken.balanceOf(factoryController);

        vm.startPrank(factoryController);
        stakeVault.recoverERC20(address(recoverToken), amount);
        // recover sends tokens to owner of lpStaking
        uint ownerBalanceAfter = recoverToken.balanceOf(factoryController);
        assertEq(ownerBalanceAfter, ownerBalanceBefore + amount);
        vm.stopPrank();
    }

    function test_setRewardDistributor_notFactory() public {
        vm.expectRevert(OnlyFactoryController.selector);
        vm.prank(alice);
        stakeVault.setRewardDistributor(address(0x1234));
    }

    function test_setRewardDistributor_addressZero() public {
        vm.expectRevert(AddressCannotBeZero.selector);
        vm.prank(factoryController);
        stakeVault.setRewardDistributor(address(0x0));
    }

    function test_setRewardDistributor() public {
        vm.prank(factoryController);
        stakeVault.setRewardDistributor(address(0x1234));
    }
}
