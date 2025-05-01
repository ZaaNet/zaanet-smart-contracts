// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IZaaNetNetwork {
    struct Network {
        uint256 id;
        address host;
        string name;
        string country;
        string city;
        string area;
        uint256 price;
        string metadataCID;
        bool isActive;
        uint256 totalRating;
        uint256 ratingCount;
        uint256 successfulSessions;
    }

    event NetworkRegistered(
        uint256 indexed networkId,
        address indexed host,
        string name,
        string city,
        string area,
        string metadataCID
    );

    event NetworkUpdated(
        uint256 indexed networkId,
        address indexed host,
        string name,
        string city,
        string area,
        string metadataCID,
        bool isActive
    );

    function registerNetwork(
        string memory name,
        string memory country,
        string memory city,
        string memory area,
        uint256 pricePerHour,
        string memory metadataCID,
        bool isActive
    ) external;

    function updateNetwork(
        uint256 networkId,
        string memory name,
        string memory country,
        string memory city,
        string memory area,
        uint256 pricePerHour,
        string memory metadataCID,
        bool isActive
    ) external;

    function getHostedNetworkById(uint256 networkId)
        external
        view
        returns (Network memory);
}
