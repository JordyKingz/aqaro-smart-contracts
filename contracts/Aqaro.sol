// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./PropertyFactory.sol";
import "./staking/MortgagePool.sol";

contract Aqaro is PropertyFactory, MortgagePool {
    /**
     * @dev Constructor function.
     *
     * @param factoryController The address that controls the factory
     */
    constructor(address factoryController) PropertyFactory(factoryController) MortgagePool(factoryController) {}

    /**
     * @dev Internal pure function to retrieve and return the name of this
     *      contract.
     *
     * @return The name of this contract.
     */
    function _name() internal pure override returns (string memory) {
        // Return the name of the contract.
        assembly {
            mstore(0x20, 0x20)
            mstore(0x47, 0x417161726f)
            return(0x20, 0x60)
        }
    }

    function _nameString() internal pure override returns (string memory) {
        // Return the name of the contract.
        return "Aqaro";
    }
}
