// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Mortgage.sol";
import "../Property.sol";
import "../structs/MortgageStructs.sol";

contract MortgageFactory is ReentrancyGuard {
    error InvalidAddress();
    error MortgageDurationInPast();
    error MortgagePaymentAmountZero();
    error CannotRequestPropertyWhenPropertyOwner();
    error MortgageAlreadyRequested(address propertyContract);
    error PropertyDoesNotExists();

    event MortgageRequested(address indexed mortgageContract, address indexed propertyContract, address indexed owner);

    address public factoryController;

    uint public interestRate = 2500; // 2.5% interest rate

    // owner => property
    mapping(address => address) public propertyMortgageRequests;
    // owner => property => mortgage
    mapping(address => mapping(address => address)) public ownerPropertyMortgage;

    address[] public mortgageContracts;

    constructor(address _factoryController) {
        factoryController = _factoryController;
    }

    function getMortgageContracts() public view returns(address[] memory) {
        return mortgageContracts;
    }

    // for every mortgage request this function is called to create new mortgage contract
    function requestMortgage(
        address propertyContract,
        MortgageRequester calldata _requester,
        MortgagePayment calldata _mortgagePayment)
    public nonReentrant {
        if (propertyContract == address(0)) {
            revert InvalidAddress();
        }
        if (_mortgagePayment.endDate < block.timestamp) {
            revert MortgageDurationInPast();
        }
        if (_mortgagePayment.amountETH == 0 || _mortgagePayment.amountUSD == 0) {
            revert MortgagePaymentAmountZero();
        }

        Property property = Property(propertyContract);

        if (property.propertyOwner() == msg.sender) {
            revert CannotRequestPropertyWhenPropertyOwner();
        }
        if (propertyMortgageRequests[msg.sender] == address(property)) {
            revert MortgageAlreadyRequested(propertyContract);
        }

        (, , , , , , uint created, ,) = property.propertyInfo();
        if (created == 0 || created > block.timestamp) {
            revert PropertyDoesNotExists();
        }

        Mortgage mortgage = new Mortgage(address(property), msg.sender, _requester, _mortgagePayment);
        propertyMortgageRequests[msg.sender] = address(property);
        ownerPropertyMortgage[msg.sender][address(property)] = address(mortgage);

        mortgageContracts.push(address(mortgage));

        emit MortgageRequested(address(mortgage), address(property), msg.sender);
    }
}
