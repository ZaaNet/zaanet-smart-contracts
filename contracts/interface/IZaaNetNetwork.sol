// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../ZaaNetStorage.sol";

interface IZaaNetNetwork {
    // ========== Events ==========

    event NetworkRegistered(
        uint256 indexed networkId,
        address indexed hostAddress,
        string mongoDataId
    );

    event NetworkUpdated(
        uint256 indexed networkId,
        address indexed hostAddress,
        uint256 pricePerHour,
        string mongoDataId,
        bool isActive
    );

    event HostAdded(address indexed newHostAddress);

    // Additional events for better tracking
    event NetworkPriceUpdated(uint256 indexed networkId, uint256 oldPrice, uint256 newPrice);
    event NetworkStatusChanged(uint256 indexed networkId, bool oldStatus, bool newStatus);

    // ========== Network Management ==========

    /// @notice Register a new WiFi network
    /// @param pricePerHour Cost in USDT per hour
    /// @param mongoDataId MongoDB document ID for metadata (e.g. JSON with SSID, location, etc.)
    /// @param isActive Whether network is available for guest discovery
    function registerNetwork(
        uint256 pricePerHour,
        string memory mongoDataId,
        bool isActive
    ) external;

    /// @notice Update an existing network
    /// @param networkId ID of the network
    /// @param pricePerHour Updated price
    /// @param isActive New active status
    function updateNetwork(
        uint256 networkId,
        uint256 pricePerHour,
        bool isActive
    ) external;

    /// @notice Fetch a network by ID
    /// @param networkId ID of the network
    /// @return Network struct with all metadata
    function getHostedNetworkById(
        uint256 networkId
    ) external view returns (ZaaNetStorage.Network memory);

    /// @notice Get all network IDs registered by a host
    /// @param hostAddress Address of the host
    /// @return networkIds List of network IDs
    function getHostNetworks(
        address hostAddress
    ) external view returns (uint256[] memory);

    /// @notice Public method to check if an address is a registered host
    /// @param hostAddress The address to verify
    /// @return isHost True if host is registered
    function isRegisteredHost(address hostAddress) external view returns (bool);
}