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
    //    string propertyGuid;
    //    bytes signature; // ?
//    bytes extraData; // ?
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
    Sold
}

struct OfferStatus {
    bool sellerAccepted;
    bool buyerAccepted;
}

