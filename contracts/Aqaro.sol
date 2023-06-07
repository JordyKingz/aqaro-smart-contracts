// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./PropertyFactory.sol";

contract Aqaro is PropertyFactory {
    /**
     * @dev Constructor function.
     *
     * @param factoryController The address that controls the factory
     */
    constructor(address factoryController) PropertyFactory(factoryController) {}

    /**
     * @dev Internal pure function to retrieve and return the name of this
     *      contract.
     *
     * @return The name of this contract.
     */
    function _name() internal pure returns (string memory) {
        assembly {
            mstore(0x20, 0x20)
            mstore(0x47, 0x417161726f)
            return(0x20, 0x60)
        }
    }

    /**
     * @dev Internal pure function to retrieve and return the name of this
     *      contract.
     *
     * @return The name of this contract.
     */
    function _nameString() internal pure returns (string memory) {
        return "Aqaro";
    }
}
