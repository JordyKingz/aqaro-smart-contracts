pragma solidity 0.8.17;

struct CreateProperty {
    Address addr;
    uint askingPrice;
//    string propertyGuid; // id from backend?
//    bytes signature; // ?
//    bytes extraData; // ?
}

struct PropertyInfo {
    uint id;
//    string propertyGuid;
    Address addr;
    uint askingPrice;
    address payable seller;
//    bytes signature; // ?
    uint created;
//    bytes extraData; // ?
    Status status;
    SellStatus sellStatus;
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
    OfferReceived,
    Accepted,
    Rejected,
    Sold,
    Processed
}

struct SellStatus {
    bool sellerAccepted;
    bool buyerAccepted;
}

