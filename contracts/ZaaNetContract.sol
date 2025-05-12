// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./ZaaNetStorage.sol";
import "./interface/IZaaNetNetwork.sol";
import "./interface/IZaaNetPayment.sol";
import "./interface/IZaaNetAdmin.sol";

contract ZaaNetContract is Ownable, Pausable {
    IZaaNetNetwork public networkContract;
    IZaaNetPayment public paymentContract;
    IZaaNetAdmin public adminContract;

    event CompositePaused(address indexed by);
    event CompositeUnpaused(address indexed by);

    constructor(
        address _networkContract,
        address _paymentContract,
        address _adminContract
    ) Ownable(msg.sender) {
        require(_networkContract != address(0), "Invalid network contract");
        require(_paymentContract != address(0), "Invalid payment contract");
        require(_adminContract != address(0), "Invalid admin contract");

        networkContract = IZaaNetNetwork(_networkContract);
        paymentContract = IZaaNetPayment(_paymentContract);
        adminContract = IZaaNetAdmin(_adminContract);
    }

    // =====================
    // Admin-only functions
    // =====================

    function setPlatformFee(uint256 _newFeePercent) external onlyOwner {
        adminContract.setPlatformFee(_newFeePercent);
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        adminContract.setTreasury(_newTreasury);
    }

    function pause() external onlyOwner {
        _pause();
        adminContract.pause();
        emit CompositePaused(msg.sender);
    }

    function unpause() external onlyOwner {
        _unpause();
        adminContract.unpause();
        emit CompositeUnpaused(msg.sender);
    }

    // =====================
    // Network management
    // =====================

    function registerNetwork(
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external whenNotPaused {
        networkContract.registerNetwork(_pricePerHour, _metadataCID, _isActive);
    }

    function updateNetwork(
        uint256 _networkId,
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external whenNotPaused {
        networkContract.updateNetwork(_networkId, _pricePerHour, _metadataCID, _isActive);
    }

    function getHostedNetworkById(
        uint256 _networkId
    ) external view returns (ZaaNetStorage.Network memory) {
        return networkContract.getHostedNetworkById(_networkId);
    }

    // =====================
    // Payment handling
    // =====================

    function acceptPayment(
        uint256 _networkId,
        uint256 _amount,
        uint256 _duration
    ) external whenNotPaused {
        paymentContract.acceptPayment(_networkId, _amount, _duration);
    }

    function getSession(
        uint256 _sessionId
    ) external view returns (ZaaNetStorage.Session memory) {
        return paymentContract.getSession(_sessionId);
    }

    // =====================
    // Emergency functions
    // =====================

    function emergencyWithdrawETH(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        recipient.transfer(address(this).balance);
    }

    function emergencyWithdrawERC20(address token, address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        require(token != address(0), "Invalid token");
        (bool success, ) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );
        require(success, "ERC20 transfer failed");
    }
}
