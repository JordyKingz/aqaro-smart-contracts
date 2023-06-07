// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Property.sol";
import "./structs/PropertyStructs.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PropertyFactory is PropertyFactoryInterface, ReentrancyGuard {
    address public factoryController;

    mapping(address => address[]) public properties; // mapping of owner to list of properties created
    mapping(uint => PropertyInfo) public propertyInfo; // mapping of property id to property info

    address[] public propertyContracts; // mapping of property address to property contract

    uint public propertyCount; // total number of properties created

    event PropertyCreated(address indexed propertyAddress, address indexed owner, uint indexed propertyId, uint askingPrice);
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
     * @dev function to get all properties for a caller
     *
     * @return Array of property addresses
     */
    function getPropertiesForCaller() public view returns(address[] memory) {
        return properties[msg.sender];
    }

    /**
     * @dev function to get all property contracts
     *
     * @return Array of property contract addresses
     */
    function getPropertyContracts() public view returns(address[] memory) {
        return propertyContracts;
    }

    /**
     * @dev function to create a new property contract
     *      owner of the property/contract is the msg.sender
     *
     * @param _property The property to create
     * @return The address of the created contract.
     */
    function createProperty(CreateProperty calldata _property) public nonReentrant returns(address) {
        ++propertyCount;

        PropertyInfo memory _propertyInfo = PropertyInfo({
            id: propertyCount,
            addr: _property.addr,
            askingPrice: _property.askingPrice,
            price: _property.price,
            description : _property.description,
            seller: Seller({
                wallet: payable(msg.sender),
                name: _property.seller.name,
                email: _property.seller.email,
                status: _property.seller.status
            }),
            status: Status.Created,
            created: block.timestamp,
            offerStatus: OfferStatus({
                sellerAccepted: false,
                buyerAccepted: false
            })
        });

        // add property to propertyInfo mapping
        propertyInfo[propertyCount] = _propertyInfo;

        // create new property contract
        Property property = new Property(address(this), msg.sender, _propertyInfo);

        // add property to properties mapping
        properties[msg.sender].push(address(property));
        propertyContracts.push(address(property));

        emit PropertyCreated(address(property), msg.sender, propertyCount, _propertyInfo.askingPrice);
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

        (uint id, , , , Seller memory seller, , , Status status, OfferStatus memory offerStatus) = property.propertyInfo();

//        require(block.timestamp >= property.propertyInfo.created, "Property does not exist");
        require(status == Status.Sold, "Property is not Sold");
        require(offerStatus.sellerAccepted == true, "Seller has not accepted the offer");
        require(offerStatus.buyerAccepted == true, "Buyer has not accepted the offer");

        // update property to propertyContracts mapping
//        propertyContracts[address(_propertyAddress)] = property;


        bool success = property.transferPropertyOwnerShip();
        require(success, "Property ownership transfer failed");

        address highestBidder = property.highestBidder();
        uint highestBid = property.highestBid();

        emit PropertySold(address(property), highestBidder, seller.wallet, highestBid, id);
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
