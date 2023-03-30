// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Property.sol";

// contract that transfers from mortgage pool to specific property owner
// currently not used, can be removed? Other implementation needed
contract MortgageProvider is ReentrancyGuard {
    address public mortgagePool;
    address public factoryController;

    uint public constant paymentPeriod = 30 days;

    constructor(address _mortgagePool, address _factoryController) {
        mortgagePool = _mortgagePool;
        factoryController = _factoryController;
    }

    modifier onlyMortgagePool() {
        require(msg.sender == mortgagePool, "Only mortgage pool can call this function");
        _;
    }

    modifier onlyFactoryController() {
        require(msg.sender == factoryController, "Only controller can call this function");
        _;
    }

    function requestMortgage(uint256 _amount, address _property) public nonReentrant {
        require(_amount > 0, "Must request a positive amount");
        require(_property != address(0), "Must request a valid property address");
        Property property = Property(_property);
        require(property.highestBid() > 0, "Must have a bid on property");
        require(property.highestBidder() != address(0), "Must have a valid bidder");
        require(_amount == property.highestBid(), "Must request the same amount as the highest bid");


        // transfer mortgage to property owner
    }
}
