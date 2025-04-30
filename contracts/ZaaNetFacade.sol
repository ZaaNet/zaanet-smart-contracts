// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ZaaNetNetwork.sol";
import "./ZaaNetPayment.sol";
import "./ZaaNetAdmin.sol";
import "./IZaaNetNetwork.sol";
import "./IZaaNetPayment.sol";
import "./IZaaNetAdmin.sol";

contract ZaaNetFacade {
    IZaaNetNetwork public networkContract;
    IZaaNetPayment public paymentContract;
    IZaaNetAdmin public adminContract;

    constructor(address _networkContract, address _paymentContract, address _adminContract) {
        networkContract = IZaaNetNetwork(_networkContract);
        paymentContract = IZaaNetPayment(_paymentContract);
        adminContract = IZaaNetAdmin(_adminContract);
    }

    // Network functions
    function registerNetwork(
        string memory _name,
        string memory _locationCity,
        string memory _locationArea,
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external {
        networkContract.registerNetwork(_name, _locationCity, _locationArea, _pricePerHour, _metadataCID, _isActive);
    }

    function updateNetwork(
        uint256 _networkId,
        string memory _name,
        string memory _locationCity,
        string memory _locationArea,
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external {
        networkContract.updateNetwork(_networkId, _name, _locationCity, _locationArea, _pricePerHour, _metadataCID, _isActive);
    }

    function getHostedNetworkById(uint256 _networkId) external view returns (ZaaNetStorage.Network memory) {
        return networkContract.getHostedNetworkById(_networkId);
    }

    // Payment functions
    function acceptPayment(uint256 _networkId, uint256 _amount, uint256 _duration) external {
        paymentContract.acceptPayment(_networkId, _amount, _duration);
    }

    function getSession(uint256 _sessionId) external view returns (ZaaNetStorage.Session memory) {
        return paymentContract.getSession(_sessionId);
    }

    // Admin functions
    function setPlatformFee(uint256 _newFeePercent) external {
        adminContract.setPlatformFee(_newFeePercent);
    }

    function setTreasury(address _newTreasury) external {
        adminContract.setTreasury(_newTreasury);
    }

    function pause() external {
        adminContract.pause();
    }

    function unpause() external {
        adminContract.unpause();
    }
}