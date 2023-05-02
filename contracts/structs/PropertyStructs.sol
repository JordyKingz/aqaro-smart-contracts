pragma solidity 0.8.17;

struct CreateProperty {
    Address addr;
    uint askingPrice;
    int price;
}

struct PropertyInfo {
    uint id;
    Address addr;
    uint askingPrice;
    int price;
    address payable seller;
    uint created;
    Status status;
    OfferStatus offerStatus;
}

struct Address {
    string street;
    string city;
    string state;
    string country;
    string zip;
}

enum Status {
    Created,
    Pending,
    BuyerAccepted,
    SellerAccepted,
    Cancelled,
    Sold,
    OfferReceived, // when no mortgage is needed
    Rejected, // when no mortgage is needed
    Accepted, // when no mortgage is needed
    Processed // when no mortgage is needed
}

struct OfferStatus {
    bool sellerAccepted;
    bool buyerAccepted;
}

