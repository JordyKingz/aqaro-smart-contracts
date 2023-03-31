// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/IAqaroToken.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AqaroPresale is ReentrancyGuard {
    AqaroTokenInterface public aqaroToken;
    address public factoryController;

    uint256 public tokenPrice = 0.0003 ether; // ~0.50$
    uint256 public softcap = 1000 ether;
    uint256 public presaleEndDate;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public ethBalances;

    constructor(address _factoryController, address _aqaroToken) {
        factoryController = _factoryController;
        aqaroToken = AqaroTokenInterface(_aqaroToken);

        presaleEndDate = block.timestamp + 60 days;
    }

    modifier onlyFactoryController() {
        require(msg.sender == factoryController, "PresaleToken: Only factory controller can call this function.");
        _;
    }

    function buyAqaroToken(uint256 _amount) external payable nonReentrant {
        require(_amount > 0, "PresaleToken: Must send ether to buy Aqaro token.");
        require(aqaroToken.balanceOf(address(this)) >= _amount, "PresaleToken: Not enough Aqaro token in the contract.");
        require(msg.value == _amount * tokenPrice, "PresaleToken: Must send the correct amount of ether.");
        balances[msg.sender] += _amount;
        ethBalances[msg.sender] += msg.value;

        aqaroToken.transfer(msg.sender, _amount);
    }

    // When softcap is not reached when presale ends, users can send back aqaro token and get their ether back.
    function withdrawEther(uint256 _amount) external nonReentrant {
        require(block.timestamp >= presaleEndDate, "PresaleToken: Presale has not ended yet.");
        require(address(this).balance < softcap, "PresaleToken: Softcap is reached");
        require(_amount == balances[msg.sender], "Amount must match the amount of Aqaro token you have.");
        require(aqaroToken.allowance(msg.sender, address(this)) >= _amount, "PresaleToken: You must approve the contract to transfer your Aqaro tokens.");
        require(aqaroToken.balanceOf(address(this)) >= _amount, "PresaleToken: Not enough tokens in the contract.");
        require(address(this).balance >= ethBalances[msg.sender], "PresaleToken: Not enough ether in the contract.");

        aqaroToken.transferFrom(msg.sender, address(this), _amount);
        payable(msg.sender).transfer(ethBalances[msg.sender]);
    }

    // transfer ETH balance to factory controller
    function transferEtherToController() external nonReentrant onlyFactoryController {
        require(block.timestamp >= presaleEndDate, "PresaleToken: Presale has not ended yet.");
        require(address(this).balance >= softcap, "PresaleToken: Softcap is not reached");
        payable(factoryController).transfer(address(this).balance);
    }
}
