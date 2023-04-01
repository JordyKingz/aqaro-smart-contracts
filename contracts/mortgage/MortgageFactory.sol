// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Mortgage.sol";
import "../Property.sol";

contract MortgageFactory is ReentrancyGuard {
    error MortgageAlreadyRequested(address propertyContract);
    error InvalidAddress();
    error PropertyDoesNotExists();

    address public factoryController;

    // owner => property
    mapping(address => address) public propertyMortgageRequests;
    // owner => property => mortgage
    mapping(address => mapping(address => address)) public ownerPropertyMortgage;

    address[] public mortgageContracts;

    event MortgageRequested(address indexed mortgageContract, address indexed propertyContract, address indexed owner);

    constructor(address _factoryController) {
        factoryController = _factoryController;
    }

    function getMortgageContracts() public view returns(address[] memory) {
        return mortgageContracts;
    }

    // for every mortgage request this function is called to create new mortgage contract
    function requestMortgage(address propertyContract, MortgageRequester memory _requester) public nonReentrant {
        if (propertyContract == address(0)) {
            revert InvalidAddress();
        }

        Property property = Property(propertyContract);

        if (propertyMortgageRequests[msg.sender] == address(property)) {
            revert MortgageAlreadyRequested(propertyContract);
        }

        (, , , , uint created, ,) = property.propertyInfo();
        if (created < block.timestamp) {
            revert PropertyDoesNotExists();
        }

        Mortgage mortgage = new Mortgage(address(property), msg.sender, _requester);
        propertyMortgageRequests[msg.sender] = address(property);
        ownerPropertyMortgage[msg.sender][address(property)] = address(mortgage);

        mortgageContracts.push(address(mortgage));

        emit MortgageRequested(address(mortgage), address(property), msg.sender);
    }
}
