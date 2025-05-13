// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../ZaaNetStorage.sol";

interface IZaaNetNetwork {
    // ========== Events ==========

    event NetworkRegistered(
        uint256 indexed networkId,
        address indexed host,
        string metadataCID
    );

    event NetworkUpdated(
        uint256 indexed networkId,
        address indexed host,
        string metadataCID,
        bool isActive
    );

    event HostAdded(address indexed newHost);

    // ========== Network Management ==========

    /// @notice Register a new WiFi network
    /// @param pricePerHour Cost in USDT per hour
    /// @param metadataCID IPFS CID for metadata (e.g. JSON with SSID, location, etc.)
    /// @param isActive Whether network is available for guest discovery
    function registerNetwork(
        uint256 pricePerHour,
        string memory metadataCID,
        bool isActive
    ) external;

    /// @notice Update an existing network
    /// @param networkId ID of the network
    /// @param pricePerHour Updated price
    /// @param metadataCID New metadata CID
    /// @param isActive New active status
    function updateNetwork(
        uint256 networkId,
        uint256 pricePerHour,
        string memory metadataCID,
        bool isActive
    ) external;

    /// @notice Fetch a network by ID
    /// @param networkId ID of the network
    /// @return Network struct with all metadata
    function getHostedNetworkById(
        uint256 networkId
    ) external view returns (ZaaNetStorage.Network memory);

    /// @notice Get all networks registered by a host
    /// @param host Address of the host
    /// @return networkIds List of network IDs
    function getHostNetworks(
        address host
    ) external view returns (uint256[] memory);

    /// @notice Public method to check if an address is a registered host
    /// @param account The address to verify
    /// @return isHost True if host is registered
    function isRegisteredHost(address account) external view returns (bool);

    // ========== Rating System ==========

    /// @notice Submit a 1–5 star rating for a network
    /// @param networkId The network being rated
    /// @param rating Value between 1 and 5
    function rateNetwork(uint256 networkId, uint8 rating) external;

    /// @notice Get the average rating (multiplied by 100 to avoid decimals)
    /// @param networkId The network to check
    /// @return averageRating E.g. 431 means 4.31 stars
    function getAverageRating(
        uint256 networkId
    ) external view returns (uint256);
}
