// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../structs/MortgageStructs.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Property.sol";

// used for mortgage => property
// todo set price to pay each month
// different states where mortgage is in
contract Mortgage is ReentrancyGuard {
    error MortgageDurationInPast();

    Property public property;
    MortgageStatus public status;

    address public propertyContract;
    address public buyer;
    int public mortgageAmount; // amount is in dollars
    uint256 public mortgageAmountEth;
//    uint256 public mortgageDuration; // timestamp in future
    uint256 public totalPayments;

    uint public startDate;
    uint public endDate;
    uint public payWindow = 14 days;
    uint public paymentInterval = 30 days;

    MortgageRequester private _requester;
    MortgagePayment private _mortgagePayment;

    uint private _paidOffAmountUsd;
    uint private _paidOffAmountEth;
    int private _restAmountUsd;
    uint private _restAmountEth;
    uint private _lastPaymentDate;

    constructor(
        address _propertyContract,
        address _buyer,
        MortgageRequester memory requester,
        MortgagePayment memory mortgagePayment
    ) {
        if (mortgagePayment.endDate < block.timestamp) {
            revert MortgageDurationInPast();
        }
        endDate = mortgagePayment.endDate;

        status = MortgageStatus.Requested;
        propertyContract = _propertyContract;
        Property property = Property(_propertyContract);

        _requester = requester;
        _mortgagePayment = mortgagePayment;
        _restAmountUsd = mortgagePayment.amountUSD;
        _restAmountEth = mortgagePayment.amountETH;

        buyer = _buyer;
        totalPayments = mortgagePayment.totalPayments;
    }
}
