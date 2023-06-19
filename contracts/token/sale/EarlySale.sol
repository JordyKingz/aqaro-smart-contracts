// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../../interfaces/IAqaroToken.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AqaroEarlySale is ReentrancyGuard {
    event Invested(address indexed _investor, uint256 _amount, uint256 _ethAmount);
    event EthTransferredToController(address indexed _controller, uint256 _ethAmount);

    error OnlyFactoryController();
    error SaleHasEnded();
    error SaleNotEnded();
    error AmountIsZero();
    error NotEnoughTokensInContract();
    error NotEnoughEthSent();

    AqaroTokenInterface public aqaroToken;
    address public factoryController;

    uint256 public tokenPrice = 0.000125 ether; // ~0.20$
    uint256 public saleEndDate;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public ethBalances;

    constructor(address _factoryController, address _aqaroToken) {
        factoryController = _factoryController;
        aqaroToken = AqaroTokenInterface(_aqaroToken);

        saleEndDate = block.timestamp + 60 days;
    }

    modifier onlyFactoryController() {
        if (msg.sender != factoryController) {
            revert OnlyFactoryController();
        }
        _;
    }

    /**
     * @dev function to invest in Aqaro token
     *
     * @param _amount The amount of Aqaro token to buy in wei
     *
     * @return success if successful
     */
    function investInAqaro(uint256 _amount) external payable nonReentrant returns (bool success) {
        if (block.timestamp > saleEndDate) {
            revert SaleHasEnded();
        }
        if (_amount == 0) {
            revert AmountIsZero();
        }
        if (aqaroToken.balanceOf(address(this)) < _amount) {
            revert NotEnoughTokensInContract();
        }
        if (msg.value != tokenPrice * _amount / 1 ether) {
            revert NotEnoughEthSent();
        }

        balances[msg.sender] += _amount;
        ethBalances[msg.sender] += msg.value;

        (success) = aqaroToken.transfer(msg.sender, _amount);
        require(success, "AqaroEarlySale: Transfer failed.");

        emit Invested(msg.sender, _amount, msg.value);
        return success;
    }

    /**
     * @dev function to transfer ETH balance to factory controller
     */
    function transferEthToController() external nonReentrant onlyFactoryController {
        if (block.timestamp < saleEndDate) {
            revert SaleNotEnded();
        }
//        require(block.timestamp >= saleEndDate, "AqaroEarlySale: Sale has not ended yet.");
        (bool success, ) = payable(factoryController).call{value: address(this).balance}("");
        require(success, "Transfer failed.");

        emit EthTransferredToController(factoryController, address(this).balance);
    }

    // transfer Aqaro token balance to factory controller
    // can only be called after presale ends
    // remaining tokens can be added to liquidity, burned, airdrop or other purposes
    // discuss if function is needed, we can let tokens in contract?
    function withdrawTokensToController() external nonReentrant onlyFactoryController {
        if (block.timestamp < saleEndDate) {
            revert SaleNotEnded();
        }
        aqaroToken.transfer(factoryController, aqaroToken.balanceOf(address(this)));
    }
}
