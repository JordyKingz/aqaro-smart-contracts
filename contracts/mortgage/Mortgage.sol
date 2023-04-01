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
    uint256 public mortgageAmount;

    MortgageRequester private _requester;

    constructor(address _propertyContract, address _buyer, MortgageRequester memory requester) {
        status = MortgageStatus.Requested;
        propertyContract = _propertyContract;
        buyer = _buyer;

        _requester = requester;
    }
}
