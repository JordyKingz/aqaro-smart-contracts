// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Property.sol";
import "./structs/PropertyStructs.sol";

contract PropertyFactory is PropertyFactoryInterface {
    address public factoryController;

    mapping(address => address) public properties;
    address[] public propertyAddresses;
    mapping(uint => PropertyInfo) public propertyInfo;

    uint public propertyCount;

    constructor(address factoryController) {
        factoryController = factoryController;
    }

    receive() external payable {}

    modifier onlyFactoryController() {
        require(msg.sender == factoryController, "Only controller can call this function");
        _;
    }

    function createProperty(CreateProperty _property) public nonReentrant returns (address) {
        // Check if the property already exists
        // require(properties[msg.sender] == address(0), "Property already exists");
        ++propertyCount;
        /// @notice this really necessary?
        PropertyInfo memory _propertyInfo = PropertyInfo({
            id: propertyCount,
            addr: _property.addr,
            askingPrice: _property.askingPrice,
            seller: msg.sender,
            signature: _property.signature,
            created: block.timestamp,
            extraData: _property.extraData,
            status: Status.Created
        });
        propertyInfo[propertyCount] = _propertyInfo;

        Property memory property = new Property(address(this), msg.sender, _propertyInfo);
        properties[msg.sender] = address(property);
        propertyAddresses.push(address(property));

        return address(property);
    }

    // only the controller can call this function
    function propertyIsSold(address propertyAddress) public onlyFactoryController nonReentrant {
        // check if propertyAddress is in propertyAddresses array
        require(propertyAddresses[propertyAddress] != address(0), "Property does not exist");

        Property memory property = Property(property);

        require(property.status == Status.Sold, "Property is not Sold");
        require(property.sellStatus.sellerAccepted == true, "Seller has not accepted the offer");
        require(property.sellStatus.buyerAccepted == true, "Buyer has not accepted the offer");

        bool success = property.transferPropertyOwnerShip();
        require(success, "Property ownership transfer failed");

        // emit
    }

    function withdraw() public onlyFactoryController nonReentrant {
        address payable _owner = payable(msg.sender);
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
