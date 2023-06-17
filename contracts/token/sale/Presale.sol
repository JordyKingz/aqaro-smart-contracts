// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../../interfaces/IAqaroToken.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AqaroPresale is ReentrancyGuard {
    AqaroTokenInterface public aqaroToken;
    address public factoryController;

    uint256 public tokenPrice = 0.0003 ether; // ~0.50$
    uint256 public softCap = 1000 ether;
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

    /**
     * @dev function to purchase Aqaro token
     *
     * @param _amount The amount of Aqaro token to buy in wei
     *
     * @return true if successful
     */
    function buyAqaroToken(uint256 _amount) external payable nonReentrant returns (bool) {
        require(block.timestamp < presaleEndDate, "PresaleToken: Presale has ended.");
        require(_amount > 0, "PresaleToken: Must send ether to buy Aqaro token.");
        require(aqaroToken.balanceOf(address(this)) >= _amount, "PresaleToken: Not enough Aqaro token in the contract.");
        require(msg.value == (_amount * tokenPrice), "PresaleToken: Must send the correct amount of ether."); // / 1 ether
        balances[msg.sender] += _amount;
        ethBalances[msg.sender] += msg.value;

        (bool success) = aqaroToken.transfer(msg.sender, _amount);
        require(success, "PresaleToken: Transfer failed.");
        return true;
    }


   /**
    * @dev function to withdraw Aqaro token balance
    *      can only be called after presale ends and softcap is not reached
    *
    * @return true if successful
    */
    function withdrawEther() external nonReentrant returns (bool) {
        require(block.timestamp >= presaleEndDate, "PresaleToken: Presale has not ended yet.");
        require(address(this).balance < softCap, "PresaleToken: Softcap is reached");
        require(aqaroToken.allowance(msg.sender, address(this)) >= balances[msg.sender], "PresaleToken: You must approve the contract to transfer your Aqaro tokens.");
        require(aqaroToken.balanceOf(address(this)) >= balances[msg.sender], "PresaleToken: Not enough tokens in the contract.");
        require(address(this).balance >= ethBalances[msg.sender], "PresaleToken: Not enough ether in the contract.");

        aqaroToken.transferFrom(msg.sender, address(this), balances[msg.sender]);

        (bool success, ) = payable(msg.sender).call{value: ethBalances[msg.sender]}("");
        require(success, "Transfer failed.");
        return true;
    }

    /**
     * @dev function to transfer ether balance to factory controller
     */
    function transferEtherToController() external nonReentrant onlyFactoryController {
        require(block.timestamp >= presaleEndDate, "PresaleToken: Presale has not ended yet.");
        require(address(this).balance >= softCap, "PresaleToken: Softcap is not reached");
        (bool success, ) = payable(factoryController).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // transfer Aqaro token balance to factory controller
    // can only be called after presale ends
    // tokens can be added to liquidity, burned, airdrop or other purpose
    // discuss if function is needed, we can let tokens in contract?
    function withdrawTokensToController() external nonReentrant onlyFactoryController {
        require(block.timestamp >= presaleEndDate, "PresaleToken: Presale has not ended yet.");
        aqaroToken.transfer(factoryController, aqaroToken.balanceOf(address(this)));
    }
}
