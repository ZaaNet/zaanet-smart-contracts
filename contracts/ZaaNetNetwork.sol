// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ZaaNetStorage.sol";
import "./IZaaNetNetwork.sol";

contract ZaaNetNetwork is Pausable, IZaaNetNetwork {
    ZaaNetStorage public storageContract;

    constructor(address _storageContract) {
        storageContract = ZaaNetStorage(_storageContract);
    }

    function registerNetwork(
        string memory _name,
        string memory _city,
        string memory _area,
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external override whenNotPaused {
        require(_pricePerHour > 0, "Price must be greater than 0");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_city).length > 0, "City cannot be empty");

        uint256 networkId = storageContract.incrementNetworkId();

        storageContract.setNetwork(
            networkId,
            ZaaNetStorage.Network({
                id: networkId,
                host: msg.sender,
                name: _name,
                country: "", // Add logic if you want to include country
                city: _city,
                area: _area,
                price: _pricePerHour,
                metadataCID: _metadataCID,
                isActive: _isActive,
                totalRating: 0,
                ratingCount: 0,
                successfulSessions: 0
            })
        );

        emit NetworkRegistered(networkId, msg.sender, _name, _city, _area, _metadataCID);
    }

    function updateNetwork(
        uint256 _networkId,
        string memory _name,
        string memory _city,
        string memory _area,
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external override whenNotPaused {
        ZaaNetStorage.Network memory network = storageContract.getNetwork(_networkId);
        require(network.id != 0, "Network does not exist");
        require(network.host == msg.sender, "Only host can update");

        storageContract.setNetwork(
            _networkId,
            ZaaNetStorage.Network({
                id: _networkId,
                host: msg.sender,
                name: _name,
                country: network.country, // Preserve country if unchanged
                city: _city,
                area: _area,
                price: _pricePerHour,
                metadataCID: _metadataCID,
                isActive: _isActive,
                totalRating: network.totalRating,
                ratingCount: network.ratingCount,
                successfulSessions: network.successfulSessions
            })
        );

        emit NetworkUpdated(_networkId, msg.sender, _name, _city, _area, _metadataCID, _isActive);
    }

    function getHostedNetworkById(uint256 _networkId) external view override returns (ZaaNetStorage.Network memory) {
        ZaaNetStorage.Network memory network = storageContract.getNetwork(_networkId);
        require(network.id != 0, "Network does not exist");
        return network;
    }
}
