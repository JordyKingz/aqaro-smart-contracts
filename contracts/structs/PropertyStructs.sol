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
    Address addr;
    uint askingPrice;
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
    OfferReceived,
    Accepted,
    Rejected,
    Sold,
    Processed
}

struct OfferStatus {
    bool sellerAccepted;
    bool buyerAccepted;
}

