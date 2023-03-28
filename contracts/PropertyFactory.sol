// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Property.sol";
import "./structs/PropertyStructs.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PropertyFactory is PropertyFactoryInterface, ReentrancyGuard {
    address public factoryController;

    mapping(address => address[]) public properties; // mapping of owner to list of properties created
    mapping(uint => PropertyInfo) public propertyInfo; // mapping of property id to property info

    mapping(address => Property) public propertyContracts; // mapping of property address to property contract

    uint public propertyCount; // total number of properties created

    event PropertyCreated(address indexed propertyAddress, address indexed owner, uint indexed propertyId);
    event PropertySold(address indexed propertyAddress, address indexed buyer, address indexed seller, uint price, uint propertyId);

    constructor(address _factoryController) {
        factoryController = _factoryController;
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
    function createProperty(CreateProperty memory _property) public nonReentrant returns (address) {
        ++propertyCount;

        PropertyInfo memory _propertyInfo = PropertyInfo({
            id: propertyCount,
            addr: _property.addr,
            askingPrice: _property.askingPrice,
            seller: payable(msg.sender),
            status: Status.Created,
            created: block.timestamp,
            offerStatus: OfferStatus({
                sellerAccepted: false,
                buyerAccepted: false
            })
//            propertyGuid:_property.propertyGuid,
//            signature: _property.signature,
//            extraData: _property.extraData,
        });

        // add property to propertyInfo mapping
        propertyInfo[propertyCount] = _propertyInfo;

        // create new property contract
        Property property = new Property(address(this), msg.sender, _propertyInfo);

        // add property to properties mapping
        properties[msg.sender].push(address(property));
        // add property to propertyAddresses array
//        propertyAddresses.push(address(property));
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
     * @param _propertyAddress The property propertyAddress to finalize
     */
    function propertyIsSold(address _propertyAddress) public onlyFactoryController nonReentrant {
        // check if propertyAddress is in propertyAddresses array
        require(_propertyAddress != address(0), "Property does not exist");

        Property property = Property(_propertyAddress);

        (uint id, Address memory addr, uint askingPrice, address payable seller, uint created, Status status, OfferStatus memory offerStatus) = property.propertyInfo();
//        require(block.timestamp >= property.propertyInfo.created, "Property does not exist");
        require(status == Status.Sold, "Property is not Sold");
        require(offerStatus.sellerAccepted == true, "Seller has not accepted the offer");
        require(offerStatus.buyerAccepted == true, "Buyer has not accepted the offer");

        // update property to propertyContracts mapping
        propertyContracts[address(_propertyAddress)] = property;


        bool success = property.transferPropertyOwnerShip();
        require(success, "Property ownership transfer failed");

        address highestBidder = property.highestBidder();
        uint highestBid = property.highestBid();

        emit PropertySold(address(property), highestBidder, seller, highestBid, id);
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
