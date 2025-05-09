// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../ZaaNetStorage.sol";

interface IZaaNetNetwork {
    event NetworkRegistered(uint256 indexed networkId, address indexed host, string metadataCID);
    event NetworkUpdated(uint256 indexed networkId, address indexed host, string metadataCID, bool isActive);

    function registerNetwork(
        uint256 pricePerHour,
        string memory metadataCID,
        bool isActive
    ) external;

    function updateNetwork(
        uint256 networkId,
        uint256 pricePerHour,
        string memory metadataCID,
        bool isActive
    ) external;

    function getHostedNetworkById(uint256 networkId)
        external
        view
        returns (ZaaNetStorage.Network memory);
}

