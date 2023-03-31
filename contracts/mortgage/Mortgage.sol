// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "../structs/MortgageStructs.sol";

// used for mortgage => property
// todo set price to pay each month
// different states where mortgage is in
contract Mortgage {
    MortgageStatus public status;
    address public propertyContract;
    address public buyer;
    uint256 public mortgageAmount;

    constructor(address _propertyContract, address _buyer) {
        status.Requested;
        propertyContract = _propertyContract;
        buyer = _buyer;
    }

}
