// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ZaaNetStorage.sol";

interface IZaaNetNetwork {
    event NetworkRegistered(
        uint256 indexed networkId,
        address indexed host,
        string name,
        string locationCity,
        string locationArea,
        string metadataCID
    );
    event NetworkUpdated(
        uint256 indexed networkId,
        address indexed host,
        string name,
        string locationCity,
        string locationArea,
        string metadataCID,
        bool isActive
    );

    function registerNetwork(
        string memory _name,
        string memory _locationCity,
        string memory _locationArea,
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external;
    function updateNetwork(
        uint256 _networkId,
        string memory _name,
        string memory _locationCity,
        string memory _locationArea,
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external;
    function getHostedNetworkById(uint256 _networkId) external view returns (ZaaNetStorage.Network memory);
}