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
    uint amountETH;
    int amountUSD;
    uint totalPayments;
    uint endDate;
    int16 interestRate;
}