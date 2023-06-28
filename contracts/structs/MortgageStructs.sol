// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

enum MortgageStatus {
    Requested,
    DAOAccepted,
    BuyerAccepted,
    SellerAccepted,
    Rejected,
    Active,
    Completed,
    OnHold // when payment is due
}

struct MortgageRequester {
    string name;
    int incomeMonthly;
    int incomeYearly;
    bool KYCVerified;
}

struct MortgagePayment {
    int amountUSD;
    uint amountETH;
    uint totalPayments;
    uint endDate;
    int16 interestRate;
}
