// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Property.sol";
import "./structs/PropertyStructs.sol";

// todo implement nonreentrant

contract PropertyFactory is PropertyFactoryInterface {
    address public factoryController;

    address[] public propertyAddresses; // list of all property addresses created
    mapping(address => address[]) public properties; // mapping of owner to list of properties created
    mapping(uint => PropertyInfo) public propertyInfo; // mapping of property id to property info

    mapping(address => Property) public propertyContracts; // mapping of property address to property contract

    uint public propertyCount; // total number of properties created

    event PropertyCreated(address indexed propertyAddress, address indexed owner, uint indexed propertyId);
    event PropertySold(address indexed propertyAddress, address indexed buyer, address indexed seller, uint price, uint indexed propertyId);

    constructor(address factoryController) {
        factoryController = factoryController;
    }

    /**
     * @dev fallback and receive function to receive ether
     */
    fallback() external payable {}
    receive() external payable {}

    modifier onlyFactoryController() {
        require(msg.sender == factoryController, "Only controller can call this function");
        _;
    }

    /**
     * @dev function to create a new property contract
     *      owner of the property/contract is the msg.sender
     *
     * @param _property The property to create
     * @return The address of the created contract.
     */
    function createProperty(CreateProperty _property) public nonReentrant returns (address) {
        ++propertyCount;
        // todo this really needed, properties are contracts
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

        // add property to propertyInfo mapping
        propertyInfo[propertyCount] = _propertyInfo;

        // create new property contract
        Property memory property = new Property(address(this), msg.sender, _propertyInfo);

        // add property to properties mapping
        properties[msg.sender].push(address(property));
        // add property to propertyAddresses array
        propertyAddresses.push(address(property));
        // add property to propertyContracts mapping
        propertyContracts[address(property)] = property;

        emit PropertyCreated(address(property), msg.sender, propertyCount);
        return address(property);
    }

    /**
     * @dev function to finalize a property sale.
     *      funds are transferred inside property.transferPropertyOwnerShip();
     *
     * @notice only the controller can call this function
     *
     * @param propertyAddress The property propertyAddress to finalize
     */
    function propertyIsSold(address propertyAddress) public onlyFactoryController nonReentrant {
        // check if propertyAddress is in propertyAddresses array
        require(propertyAddresses[propertyAddress] != address(0), "Property does not exist");
        require(propertyContracts[propertyAddress].created <= block.timestamp, "Property does not exist");

        Property memory property = Property(propertyAddress);

        require(property.status == Status.Sold, "Property is not Sold");
        require(property.sellStatus.sellerAccepted == true, "Seller has not accepted the offer");
        require(property.sellStatus.buyerAccepted == true, "Buyer has not accepted the offer");

        // update property to propertyContracts mapping
        propertyContracts[address(propertyAddress)] = property;
        PropertyInfo memory _propertyInfo = property.propertyInfo();
        propertyInfo[_propertyInfo.id] = _propertyInfo;

        bool success = property.transferPropertyOwnerShip();
        require(success, "Property ownership transfer failed");

        emit PropertySold(address(property), property.highestBidder, _propertyInfo.seller, property.highestBid, _propertyInfo.id);
    }

    /**
     * @dev function to send received ETH to controller of this contract
     *      todo: implement vault to receive ETH
     */
    function withdraw() public onlyFactoryController nonReentrant {
        address payable _owner = payable(msg.sender);
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
