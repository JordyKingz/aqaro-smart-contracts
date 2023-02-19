// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./interfaces/IPropertyFactory.sol";
import "./structs/PropertyStructs.sol";

contract Property {
    PropertyFactoryInterface public _factory;
    PropertyInfo public propertyInfo;

    // kosten koper currently paid by seller
    uint public platformFee = 2;
    uint public mortgageFee = 3;

    address public propertyOwner;
    uint public highestBid;
    address public highestBidder;
    uint public created;

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

    function transferPropertyOwnerShip(address _owner) public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status != Status.Sold, "Property is already sold");
        propertyOwner = _owner;
    }

    function bid() public payable nonReentrant {
        require(propertyInfo.status == Status.Created, "Property is not open for bidding");
        require(highestBidder != msg.sender, "Already the highest bidder");
        require(msg.value > propertyInfo.askingPrice * 0.9, "Bid amount must be greater than 10% below asking price");
        require(msg.value > highestBid, "Bid amount must be greater than highest bid");
        require(propertyInfo.seller != msg.sender, "Seller cannot bid on their own property");

        highestBid = msg.value;
        highestBidder = msg.sender;
        propertyInfo.Status = Status.OfferReceived;
    }

    function secondBid() public payable nonReentrant {
        require(propertyInfo.status == Status.Rejected, "secondBid not allowed when offer is not rejected");
        require(highestBidder != msg.sender, "Already the highest bidder");
        require(msg.value > propertyInfo.askingPrice * 0.9, "Bid amount must be greater than 10% below asking price");
        require(msg.value > highestBid, "Bid amount must be greater than highest bid");
        require(propertyInfo.seller != msg.sender, "Seller cannot bid on their own property");

        highestBid = msg.value;
        highestBidder = msg.sender;
        propertyInfo.Status = Status.OfferReceived;
    }

    function acceptBid() public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status == Status.OfferReceived, "Property is not open for bidding");
        require(highestBid > 0, "No bids have been made");
        propertyInfo.status = Status.Accepted;
        propertyInfo.sellStatus.sellerAccepted = true;
    }

    function acceptAsBuyer() public onlyHighestBidder nonReentrant {
        require(propertyInfo.status == Status.Accepted, "Bid not accepted");
        require(msg.sender == highestBidder, "Only highest bidder can accept the sell");
        propertyInfo.sellStatus.buyerAccepted = true;
    }

    function finalizeSellForProperty() public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status == Status.Accepted, "Bid not accepted");
        require(propertyInfo.sellStatus.sellerAccepted, "Seller has not accepted the sell");
        require(propertyInfo.sellStatus.buyerAccepted, "Buyer has not accepted the sell");

        propertyInfo.status = Status.Sold;
    }

    function rejectBid() public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status == Status.OfferReceived, "Property is not open for bidding");
        require(highestBid > 0, "No bids have been made");
        propertyInfo.status = Status.Rejected;
    }

    function transferPropertyOwnerShip() external onlyFactory nonReentrant returns (bool success) {
        require(propertyInfo.status == Status.Sold, "Property is not sold");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract has no balance");

        propertyOwner = highestBidder;

        success = _transferPropertyFunds();
        require(success, "Transfer property funds failed.");

        propertyInfo.status = Status.Processed;

        emit PropertyOwnerShipTransferred(propertyInfo.seller, propertyOwner);
        return success;
    }

    function _transferPropertyFunds() internal returns (bool) {
        // take 2% fee from contract balance
        uint256 fee = contractBalance * platformFee / 100;
        (bool success, ) = _factory.call{value: fee}("");
        require(success, "Transfer fee to factory failed.");

        // transfer mortgageFee to mortgage contract
        uint256 mFee = contractBalance * mortgageFee / 100;
        (bool success, ) = _factory.call{value: fee}("");
        require(success, "Transfer fee to factory failed.");

        uint amountAfterFee = contractBalance - fee - mFee;

        address payable seller = propertyInfo.seller;

        (bool success, ) = seller.call{value: amountAfterFee}("");
        require(success, "Transfer failed.");
        return true;
    }
}
