// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ZaaNetStorage is Ownable {
   struct Network {
        uint256 id;
        address host;
        uint256 price;             // price per per hour
        string metadataCID;        // IPFS CID pointing to full metadata JSON
        bool isActive;
        uint256 totalRating;
        uint256 ratingCount;
        uint256 successfulSessions;
    }

    // Session content
    struct Session {
        uint256 sessionId;
        uint256 networkId;
        address guest;
        uint256 duration;
        uint256 amount;
        bool active;
    }

    mapping(uint256 => Network) public networks;
    mapping(uint256 => Session) public sessions;
    mapping(address => mapping(uint256 => bool)) public hasRated;

    uint256 public networkIdCounter;
    uint256 public sessionIdCounter;

    constructor() Ownable(msg.sender) {}

    // Network Logic
    function setNetwork(uint256 _networkId, Network memory _network) external onlyOwner {
        networks[_networkId] = _network;
    }

    function getNetwork(uint256 _networkId) external view returns (Network memory) {
        return networks[_networkId];
    }

    function incrementNetworkId() external onlyOwner returns (uint256) {
        return ++networkIdCounter;
    }

    // Session Logic
    function setSession(uint256 _sessionId, Session memory _session) external onlyOwner {
        sessions[_sessionId] = _session;
    }

    function getSession(uint256 _sessionId) external view returns (Session memory) {
        return sessions[_sessionId];
    }

    function incrementSessionId() external onlyOwner returns (uint256) {
        return ++sessionIdCounter;
    }

    function incrementSuccessfulSessions(uint256 networkId) external onlyOwner {
        networks[networkId].successfulSessions += 1;
    }

    // Rating Logic
    function markRated(address user, uint256 networkId) external onlyOwner {
        hasRated[user][networkId] = true;
    }
}
