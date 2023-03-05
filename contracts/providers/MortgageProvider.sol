// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;



// contract that transfers from mortgage pool to specific property owner
contract MortgageProvider {
    address public mortgagePool;

    constructor(address _mortgagePool) {
        mortgagePool = _mortgagePool;
    }

    modifier onlyMortgagePool() {
        require(msg.sender == mortgagePool, "Only mortgage pool can call this function");
        _;
    }
}
