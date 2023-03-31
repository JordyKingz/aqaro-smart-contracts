// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Mortgage.sol";
import "../Property.sol";

contract MortgageFactory {
    error MortgageAlreadyRequested(address propertyContract);
    error InvalidAddress();
    error PropertyNotCreated();

    // owner => property
    mapping(address => address) public propertyMortgageRequests;
    // owner => property => mortgage
    mapping(address => mapping(address => address)) public ownerPropertyMortgage;

    constructor() {}

    // for every mortgage request this function is called to create new mortgage contract
    function createMortgage(address propertyContract) public {
        if (propertyContract == address(0)) {
            revert InvalidAddress();
        }

        Property property = Property(propertyContract);

        if (propertyMortgageRequests[msg.sender] == address(property)) {
            revert MortgageAlreadyRequested(propertyContract);
        }

        if (property.propertyInfo().created < block.timestamp) {
            revert PropertyNotCreated();
        }

        Mortgage mortgage = new Mortgage(address(property), msg.sender, );
        propertyMortgageRequests[msg.sender] = address(property);
        ownerPropertyMortgage[msg.sender][address(property)] = address(mortgage);

    }
}
