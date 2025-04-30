// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ZaaNetStorage is Ownable {
    struct Network {
        uint256 id;
        address host;
        string name;
        string country;
        string city;
        string area;
        uint256 price;
        string metadataCID; // IPFS CID for image, description, speed
        bool isActive;
        uint256 totalRating; // Sum of all ratings received
        uint256 ratingCount; // Number of ratings received
        uint256 successfulSessions; // Tracked successful sessions
    }

    struct Session {
        uint256 sessionId;
        uint256 networkId;
        address guest;
        uint256 duration; // Hours
        uint256 amount; // USDT in wei
        bool active;
    }

    mapping(uint256 => Network) public networks;
    mapping(uint256 => Session) public sessions;
    mapping(address => mapping(uint256 => bool)) public hasRated; // guest => (networkId => rated)

    uint256 public networkIdCounter;
    uint256 public sessionIdCounter;

    constructor() Ownable(msg.sender) {}

    // --------- Network Logic ---------
    function setNetwork(uint256 _networkId, Network memory _network) external onlyOwner {
        networks[_networkId] = _network;
    }

    function getNetwork(uint256 _networkId) external view returns (Network memory) {
        return networks[_networkId];
    }

    function incrementNetworkId() external onlyOwner returns (uint256) {
        return ++networkIdCounter;
    }

    // --------- Session Logic ---------
    function setSession(uint256 _sessionId, Session memory _session) external onlyOwner {
        sessions[_sessionId] = _session;
    }

    function getSession(uint256 _sessionId) external view returns (Session memory) {
        return sessions[_sessionId];
    }

    function incrementSessionId() external onlyOwner returns (uint256) {
        return ++sessionIdCounter;
    }

    // --------- Reputation Logic ---------

    /// @notice Rate a network (1 to 5 stars)
    function rateNetwork(uint256 networkId, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(!hasRated[msg.sender][networkId], "Already rated");

        networks[networkId].totalRating += rating;
        networks[networkId].ratingCount += 1;
        hasRated[msg.sender][networkId] = true;
    }

    /// @notice Returns the average rating (multiplied by 100 for 2 decimals)
    function getAverageRating(uint256 networkId) external view returns (uint256) {
        Network memory n = networks[networkId];
        if (n.ratingCount == 0) return 0;
        return (n.totalRating * 100) / n.ratingCount; // e.g. 431 = 4.31 stars
    }

    /// @notice Track when a session completes (to be called externally)
    function incrementSuccessfulSessions(uint256 networkId) external onlyOwner {
        networks[networkId].successfulSessions += 1;
    }
}
