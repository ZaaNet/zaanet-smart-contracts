// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ZaaNetStorage {
    struct Network {
        uint256 id;
        address host;
        uint256 price;
        string metadataCID;
        bool isActive;
        uint256 totalRating;
        uint256 ratingCount;
        uint256 successfulSessions;
    }

    struct Session {
        uint256 sessionId;
        uint256 networkId;
        address guest;
        uint256 duration;
        uint256 amount;
        bool active;
    }

    address public owner;
    mapping(address => bool) public allowedCallers;

    uint256 public networkIdCounter;
    uint256 public sessionIdCounter;

    mapping(uint256 => Network) public networks;
    mapping(uint256 => Session) public sessions;
    mapping(address => mapping(uint256 => bool)) public hasRated;
    mapping(address => uint256) public hostEarnings;

    modifier onlyAllowed() {
        require(allowedCallers[msg.sender], "Not authorized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    event AllowedCallerUpdated(address indexed caller, bool status);
    event NetworkStored(uint256 indexed id, address indexed host);
    event SessionStored(uint256 indexed sessionId, address indexed guest);
    event HostEarningsUpdated(address indexed host, uint256 totalEarned);
    event RatingMarked(address indexed user, uint256 indexed networkId);

    constructor() {
        owner = msg.sender;
    }

    function setAllowedCaller(address _caller, bool status) external onlyOwner {
        allowedCallers[_caller] = status;
        emit AllowedCallerUpdated(_caller, status);
    }

    // --- Network Functions ---
    function incrementNetworkId() external onlyAllowed returns (uint256) {
        return ++networkIdCounter;
    }

    function setNetwork(uint256 id, Network calldata net) external onlyAllowed {
        networks[id] = net;
        emit NetworkStored(id, net.host);
    }

    function getNetwork(uint256 id) external view returns (Network memory) {
        return networks[id];
    }

    function incrementSuccessfulSessions(uint256 id) external onlyAllowed {
        networks[id].successfulSessions += 1;
    }

    // --- Session Functions ---
    function incrementSessionId() external onlyAllowed returns (uint256) {
        return ++sessionIdCounter;
    }

    function setSession(uint256 id, Session calldata session) external onlyAllowed {
        sessions[id] = session;
        emit SessionStored(id, session.guest);
    }

    function getSession(uint256 id) external view returns (Session memory) {
        return sessions[id];
    }

    // --- Ratings ---
    function markRated(address user, uint256 networkId) external onlyAllowed {
        hasRated[user][networkId] = true;
        emit RatingMarked(user, networkId);
    }

    // --- Earnings ---
    function increaseHostEarnings(address host, uint256 amount) external onlyAllowed {
        hostEarnings[host] += amount;
        emit HostEarningsUpdated(host, hostEarnings[host]);
    }

    function getHostEarnings(address host) external view returns (uint256) {
        return hostEarnings[host];
    }
}
