pragma solidity 0.8.17;

enum MortgageStatus {
    Requested,
    DAOAccepted,
    BuyerAccepted,
    SellerAccepted,
    Rejected,
    Active,
    Completed
}

struct MortgageRequester {
    string name;
    uint income;
    bool KYCVerified;
}

struct MortgagePayment {
    uint amount;
    uint duration;
    int8 interestRate;
}