// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../structs/MortgageStructs.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// used for mortgage => property
// todo set price to pay each month
// different states where mortgage is in
contract Mortgage is ReentrancyGuard {
    MortgageStatus public status;

    address public propertyContract;
    address public buyer;
    int public mortgageAmount; // amount is in dollars
    uint256 public mortgageAmountEth;
    uint256 public mortgageDuration; // timestamp in future


    uint public startDate;
    uint public payWindow = 7 days;
    uint public paymentInterval = 30 days;

    MortgageRequester private _requester;
    MortgagePayment private _mortgagePayment;

    constructor(
        address _propertyContract,
        address _buyer,
        MortgageRequester memory requester,
        MortgagePayment memory mortgagePayment
    ) {
        status = MortgageStatus.Requested;
        propertyContract = _propertyContract;
        buyer = _buyer;

        _requester = requester;
        _mortgagePayment = mortgagePayment;
    }
}
