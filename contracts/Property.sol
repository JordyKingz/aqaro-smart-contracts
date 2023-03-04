// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IPropertyFactory.sol";
import "./structs/PropertyStructs.sol";

// todo implement nonreentrant

contract Property {
    PropertyFactoryInterface public _factory;
    PropertyInfo public propertyInfo;

    // kosten koper currently paid by seller
    uint public constant platformFee = 1; // scaling scale?
    uint public constant mortgageFee = 1; // scaling scale?

    address public propertyOwner;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public created;

    event PropertyOwnerShipTransferred(address indexed seller, address indexed buyer);

    constructor(address factory, address _propertyOwner, PropertyInfo memory property) {
        _factory = factory;
        propertyOwner = _propertyOwner;
        info = property;

        created = block.timestamp;
    }

    modifier onlyFactory() {
        require(msg.sender == address(_factory), "Only factory can call this function");
        _;
    }

    modifier onlyPropertyOwner() {
        require(msg.sender == propertyOwner, "Only property owner can call this function");
        _;
    }

    modifier onlyHighestBidder() {
        require(msg.sender == highestBidder, "Only highest bidder can call this function");
        _;
    }

    /**
     * @dev function to transfer property contract ownership to new owner
     *
     * @notice only the property owner can call this function before the property is sold
     */
    function transferPropertyOwnerShipBetweenOwners(address _owner) public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status != Status.Sold, "Property is already sold");
        propertyOwner = _owner;
    }

    /**
     * @dev function to bid on the property
     */
    function bid() public payable nonReentrant {
        require(propertyInfo.status == Status.Created, "Property is not open for bidding");
        require(highestBidder != msg.sender, "Already the highest bidder");
        require(msg.value > propertyInfo.askingPrice * 0.9, "Bid amount must be greater than 10% below asking price"); // todo needed?
        require(msg.value > highestBid, "Bid amount must be greater than highest bid");
        require(propertyInfo.seller != msg.sender, "Seller cannot bid on their own property");

        highestBid = msg.value;
        highestBidder = msg.sender;
        propertyInfo.Status = Status.OfferReceived;
    }

    /**
     * @dev function to bid again when bid is rejected
     */
    function bigAgain() public payable nonReentrant {
        require(propertyInfo.status == Status.Rejected, "secondBid not allowed when offer is not rejected");
        require(highestBidder != msg.sender, "Already the highest bidder");
        require(msg.value > propertyInfo.askingPrice * 0.9, "Bid amount must be greater than 10% below asking price");
        require(msg.value > highestBid, "Bid amount must be greater than highest bid");
        require(propertyInfo.seller != msg.sender, "Seller cannot bid on their own property");

        highestBid = msg.value;
        highestBidder = msg.sender;
        propertyInfo.Status = Status.OfferReceived;
    }

    /**
     * @dev function to accept the sell as a seller
     *
     * @notice only the property owner can call this function
     */
    function acceptBid() public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status == Status.OfferReceived, "Property is not open for bidding");
        require(highestBid > 0, "No bids have been made");
        propertyInfo.status = Status.Accepted;
        propertyInfo.sellStatus.sellerAccepted = true;
    }

    /**
     * @dev function to accept the sell as a buyer
     *
     * @notice only the highest bidder can call this function
     */
    function acceptAsBuyer() public onlyHighestBidder nonReentrant {
        require(propertyInfo.status == Status.Accepted, "Bid not accepted");
        require(msg.sender == highestBidder, "Only highest bidder can accept the sell");
        propertyInfo.sellStatus.buyerAccepted = true;
    }

    /**
     * @dev function to finalize the sell. Seller must accept the sell and buyer must accept the sell
     *      factory can call transferOwnership after seller has finalized the sell
     *
     * @notice only the property owner can call this function
     */
    function finalizeSellForProperty() public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status == Status.Accepted, "Bid not accepted");
        require(propertyInfo.sellStatus.sellerAccepted, "Seller has not accepted the sell");
        require(propertyInfo.sellStatus.buyerAccepted, "Buyer has not accepted the sell");

        propertyInfo.status = Status.Sold;
    }

    /**
     * @dev function to reject the bid
     *
     * @notice only the property owner can call this function
     */
    function rejectBid() public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status == Status.OfferReceived, "Property is not open for bidding");
        require(highestBid > 0, "No bids have been made");
        propertyInfo.status = Status.Rejected;
    }

    /**
     * @dev function to transfer property ownership to highest bidder
     *
     * @notice only the factory can call this function
     *
     * @return success
     */
    function transferPropertyOwnerShip() external onlyFactory nonReentrant returns (bool success) {
        require(propertyInfo.status == Status.Sold, "Property is not sold");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract has no balance");

        propertyOwner = highestBidder;
        propertyInfo.status = Status.Processed;

        success = _transferPropertyFunds();
        require(success, "Transfer property funds failed.");

        emit PropertyOwnerShipTransferred(propertyInfo.seller, propertyOwner);
        return success;
    }

    /**
     * @dev internal function to transfer funds to seller
     *
     * @notice mortgage fee is paid to mortgage contract and is %
     * @notice platform fee is paid to factory contract and is 2%
     *
     * @return true if all transfers are successful
     */
    function _transferPropertyFunds() internal returns (bool) {
        // take 1% fee from contract balance
        uint256 fee = contractBalance * platformFee / 100;
//        (bool success, ) = _factory.call{value: fee}("");
//        require(success, "Transfer fee to factory failed.");

        // todo transfer mortgageFee to mortgage contract
        uint256 mFee = contractBalance * mortgageFee / 100;
        uint256 totalFee = fee + mFee;
        // total fee transferred
        (bool success, ) = _factory.call{value: totalFee}("");
        require(success, "Transfer fee to factory failed.");

        uint amountAfterFee = contractBalance - totalFee;

        address payable seller = propertyInfo.seller;

        (bool success, ) = seller.call{value: amountAfterFee}("");
        require(success, "Transfer failed.");
        return true;
    }
}
