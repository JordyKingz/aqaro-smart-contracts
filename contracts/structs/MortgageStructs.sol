pragma solidity 0.8.17;

enum MortgageStatus {
    Requested,
    Accepted,
    Rejected,
    Active,
    Completed
}

struct MortgageRequester {
    string name;
    uint income;
}