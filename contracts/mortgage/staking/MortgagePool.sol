// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IMortgagePool.sol";

contract MortgagePool is MortgagePoolInterface, ReentrancyGuard {
    address public factoryController;

    uint256 public totalBalance;
    mapping(address => uint256) public mortgageLiquidity;

    address[] public mortgageProviders;

    constructor(address _factoryController) {
        factoryController = _factoryController;
    }

    modifier onlyFactoryController() {
        require(msg.sender == factoryController, "Only controller can call this function");
        _;
    }

    // fallback and receive
    fallback() external payable {
        provideMortgageLiquidity();
    }
    receive() external payable {
        provideMortgageLiquidity();
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getMortgageProviders() external view returns (address[] memory) {
        return mortgageProviders;
    }

    function getMortgageLiquidityAmount(address _mortgageProvider) external view returns (uint256) {
        return mortgageLiquidity[_mortgageProvider];
    }

    function provideMortgageLiquidity() public payable nonReentrant {
        require(msg.value > 0, "Must send ether to provide liquidity");

        totalBalance += msg.value;
        mortgageLiquidity[msg.sender] += msg.value;
        mortgageProviders.push(msg.sender);
    }
}
