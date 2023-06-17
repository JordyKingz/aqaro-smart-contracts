// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IPropertyFactory.sol";
import "../structs/PropertyStructs.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Property is ReentrancyGuard {
    PropertyFactoryInterface public factory;
    PropertyInfo public propertyInfo;

    error BiddingNotOpen(uint256 bidOpenTime);
    error NotEnoughBalance(uint256 requested, uint256 available);

    // kosten koper currently paid by seller
    uint public constant platformFee = 2; // scaling scale?

    address public propertyOwner;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public created;

    // after creating the property there is a time window of 7 days before bidding is set to open
    // this gives people who needs mortgages time to request a mortgage for specific properties
    // and enter the bidding process
    uint256 public biddingOpenTime;

    event PropertyOwnerShipTransferred(address indexed seller, address indexed buyer);

    constructor(address _factory, address _propertyOwner, PropertyInfo memory property) {
        factory = PropertyFactoryInterface(_factory);
        propertyInfo = property;
        propertyOwner = _propertyOwner;
        created = block.timestamp;

        biddingOpenTime = block.timestamp + 7 days;
    }

    modifier onlyFactory() {
        require(msg.sender == address(factory), "Only factory can call this function");
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
     * create array of different bids
     * todo seller can accept any bid and doesnt have to be higher than previous bid
     */
    function bid(uint256 offer) public nonReentrant {
        if (block.timestamp < biddingOpenTime) {
            revert BiddingNotOpen(biddingOpenTime);
        }
        require(propertyInfo.status == Status.Created, "Property is not open for bidding");
        require(highestBidder != msg.sender, "Already the highest bidder");
//        require(offer > propertyInfo.askingPrice * 0.9, "Bid amount must be greater than 10% below asking price"); // todo needed?
        require(offer > highestBid, "Bid amount must be greater than highest bid");
        require(propertyInfo.seller.wallet != msg.sender, "Seller cannot bid on their own property");

        highestBid = offer;
        highestBidder = msg.sender;
        propertyInfo.status = Status.OfferReceived;
    }

    /**
     * @dev function to bid again when bid is rejected
     */
    function bidAgain(uint256 offer) public nonReentrant {
        require(propertyInfo.status == Status.Rejected, "secondBid not allowed when offer is not rejected");
        require(highestBidder != msg.sender, "Already the highest bidder");
//        require(offer > propertyInfo.askingPrice * 0.9, "Bid amount must be greater than 10% below asking price");
        require(offer > highestBid, "Bid amount must be greater than highest bid");
        require(propertyInfo.seller.wallet != msg.sender, "Seller cannot bid on their own property");

        highestBid = offer;
        highestBidder = msg.sender;
        propertyInfo.status = Status.OfferReceived;
    }

    /** deprecated
     * @dev function to accept the sell as a seller
     *
     * @notice only the property owner can call this function
     */
    function acceptBid() public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status == Status.OfferReceived, "Property is not open for bidding");
        require(highestBid > 0, "No bids have been made");
        propertyInfo.status = Status.Accepted;
        propertyInfo.offerStatus.sellerAccepted = true;
    }

    /**
     * @dev function to accept the sell as a buyer
     *
     * @notice only the highest bidder can call this function
     */
    function acceptAsBuyer() public payable onlyHighestBidder nonReentrant {
        require(propertyInfo.status == Status.Accepted, "Bid not accepted");
        require(msg.sender == highestBidder, "Only highest bidder can accept the sell");
        require(msg.value == highestBid, "Incorrect amount sent"); // now funds are transferred to the contract
        propertyInfo.offerStatus.buyerAccepted = true;
    }

    // todo implement
    function acceptAsBuyerWithMortgage(uint256 mortgageAmount) public payable onlyHighestBidder nonReentrant {
        require(propertyInfo.status == Status.Accepted, "Bid not accepted");
        require(msg.sender == highestBidder, "Only highest bidder can accept the sell");
        require(msg.value == highestBid, "Incorrect amount sent"); // now funds are transferred to the contract
        // todo implement way that msg.value is given from mortgage pool
        propertyInfo.offerStatus.buyerAccepted = true;
    }

    /**
     * @dev function to finalize the sell. Seller must accept the sell and buyer must accept the sell
     *      factory can call transferOwnership after seller has finalized the sell
     *
     * @notice only the property owner can call this function
     */
    function finalizeSellForProperty() public onlyPropertyOwner nonReentrant {
        require(propertyInfo.status == Status.Accepted, "Bid not accepted");
        require(propertyInfo.offerStatus.sellerAccepted, "Seller has not accepted the sell");
        require(propertyInfo.offerStatus.buyerAccepted, "Buyer has not accepted the sell");

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

        success = _transferPropertyFunds(contractBalance);
        require(success, "Transfer property funds failed.");

        emit PropertyOwnerShipTransferred(propertyInfo.seller.wallet, propertyOwner);
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
    function _transferPropertyFunds(uint256 contractBalance) internal returns (bool) {
        // take 1% fee from contract balance
        uint256 fee = contractBalance * platformFee / 100;
//        (bool success, ) = _factory.call{value: fee}("");
//        require(success, "Transfer fee to factory failed.");
        // total fee transferred
        (bool factorySuccess, ) = address(factory).call{value: fee}("");
        require(factorySuccess, "Transfer fee to factory failed.");

        uint amountAfterFee = contractBalance - fee;

        address payable seller = propertyInfo.seller.wallet;

        (bool success, ) = seller.call{value: amountAfterFee}("");
        require(success, "Transfer failed.");
        return true;
    }
}
