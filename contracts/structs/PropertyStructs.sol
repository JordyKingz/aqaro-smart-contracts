// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

struct CreateProperty {
    Address addr;
    Seller seller;
    string description;
    uint askingPrice;
    string service_id;
    int price;
}

struct PropertyInfo {
    uint id;
    string service_id;
    Address addr;
    uint askingPrice;
    int price;
    Seller seller;
    string description;
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

struct Seller {
    address payable wallet;
    string name;
    string email;
    KYCStatus status;
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

enum KYCStatus {
    NONE,
    PENDING,
    VERIFIED
}

struct OfferStatus {
    bool sellerAccepted;
    bool buyerAccepted;
}

