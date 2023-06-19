pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../../contracts/token/sale/EarlySale.sol";
import "../../contracts/token/AqaroToken.sol";

contract EarlySaleTest is Test {
    error SaleHasEnded();
    error AmountIsZero();
    error NotEnoughTokensInContract();
    error NotEnoughEthSent();

    AqaroEarlySale public earlySale;
    AqaroToken public aqaroToken;

    uint256 public tokenPrice = 0.000125 ether; // ~0.20$
    uint256 public saleEndDate;

    address public factoryController = address(0xABCD);

    address public alice = address(0x1234);
    address public bob = address(0x5678);
    address public charlie = address(0x9ABC);

    function setUp() public {
        aqaroToken = new AqaroToken(factoryController);
        earlySale = new AqaroEarlySale(factoryController, address(aqaroToken));
        saleEndDate = block.timestamp + 60 days;

        // provide some ETH
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);

        vm.prank(factoryController);
        aqaroToken.transfer(address(earlySale), 3_000_000e18); // 3M
    }

    function test_endDate() public {
        assertEq(saleEndDate == block.timestamp + 60 days);
    }

    function test_tokenPrice() public {
        assertEq(tokenPrice == 0.000125 ether);
    }

    function test_factoryController() public {
        assertEq(factoryController == address(0xABCD));
    }

    function test_contractTokenBalance() public {
        assertEq(aqaroToken.balanceOf(address(earlySale)) == 3_000_000e18);
    }

    function test_investInAqaro_shouldFail_SaleEnded(uint _amount) public payable {
        vm.warp(saleEndDate + 1);
        vm.expectRevert(SaleHasEnded.selector);
        earlySale.investInAqaro{value: msg.value}(_amount);
    }

    function test_investInAqaro_shouldFail_AmountIsZero(uint _amount) public payable {
        vm.assume(_amount == 0);
        vm.expectRevert(AmountIsZero.selector);
        earlySale.investInAqaro{value: msg.value}(_amount);
    }

    function test_investInAqaro_shouldFail_NotEnoughTokensInContract(uint _amount) public payable {
        vm.assume(_amount > 0);
        vm.assume(aqaroToken.balanceOf(address(earlySale)) < _amount);
        vm.expectRevert(NotEnoughTokensInContract.selector);
        earlySale.investInAqaro{value: msg.value}(_amount);
    }

    function test_investInAqaro_shouldFail_NotEnoughEthSent(uint _amount) public payable {
        vm.assume(_amount > 0);

        vm.assume(aqaroToken.balanceOf(address(earlySale)) > _amount);
        uint value = tokenPrice * _amount / 1 ether;
        vm.assume(msg.value != value);
        vm.prank(alice);
        vm.expectRevert(NotEnoughEthSent.selector);
        earlySale.investInAqaro{value: msg.value}(_amount);
    }

    function test_investInAqaro_shouldSucceed(uint _amount) public payable {
        vm.assume(_amount > 0);
        vm.assume(aqaroToken.balanceOf(address(earlySale)) > _amount);
        uint value = tokenPrice * _amount / 1 ether;
        vm.assume(msg.value == value);
        vm.prank(alice);
        earlySale.investInAqaro{value: msg.value}(_amount);

        // check balances
        uint256 ethBalance = earlySale.ethBalances(alice);
        uint256 tokenBalance = earlySale.balances(alice);
        uint256 aqaroBalance = aqaroToken.balanceOf(alice);

        assertEq(ethBalance == msg.value);
        assertEq(tokenBalance == _amount);
        assertEq(aqaroBalance == _amount);
    }

}