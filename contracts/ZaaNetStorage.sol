// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ZaaNetStorage is Ownable, ReentrancyGuard {
    // Constants for better maintainability
    uint256 public constant MAX_NETWORKS_PER_QUERY = 100;
    uint256 public constant MAX_SESSIONS_PER_QUERY = 100;

    struct Network {
        uint256 id;
        address hostAddress;
        uint256 pricePerSession;
        string mongoDataId;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Session {
        uint256 sessionId;
        uint256 networkId;
        address paymentAddress;
        uint256 amount;
        bool active;
        uint256 voucherId;
        uint256 userId;
        uint256 startTime;
    }

    mapping(address => bool) public allowedCallers; // Addresses allowed to call storage functions
    uint256 public networkIdCounter; // Counter for network IDs
    uint256 public sessionIdCounter; // Counter for session IDs
    mapping(uint256 => Network) public networks;
    mapping(uint256 => Session) public sessions;
    mapping(address => uint256) public hostEarnings;

    // New mappings for better data management
    mapping(address => uint256[]) public hostNetworkIds;
    mapping(uint256 => bool) public networkExists;
    mapping(uint256 => bool) public sessionExists;

    modifier onlyAllowed() {
        require(allowedCallers[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    event AllowedCallerUpdated(address indexed caller, bool status);
    event NetworkStored(uint256 indexed id, address indexed hostAddress, uint256 pricePerSession);
    event NetworkUpdated(uint256 indexed id, address indexed hostAddress);
    event SessionStored(uint256 indexed sessionId, address indexed paymentAddress, uint256 amount);
    event HostEarningsUpdated(address indexed hostAddress, uint256 totalEarned);

    constructor() Ownable(msg.sender) {}

    function setAllowedCaller(address _caller, bool status) external onlyOwner {
        require(_caller != address(0), "Invalid caller address");
        allowedCallers[_caller] = status;
        emit AllowedCallerUpdated(_caller, status);
    }

    // Batch set allowed callers for initial setup
    function setAllowedCallers(address[] calldata _callers, bool status) external onlyOwner {
        for (uint256 i = 0; i < _callers.length; i++) {
            require(_callers[i] != address(0), "Invalid caller address");
            allowedCallers[_callers[i]] = status;
            emit AllowedCallerUpdated(_callers[i], status);
        }
    }

    // --- Network Functions ---
    function incrementNetworkId() external onlyAllowed returns (uint256) {
        return ++networkIdCounter;
    }

    function setNetwork(uint256 id, Network calldata net) external onlyAllowed {
        require(id > 0, "Invalid network ID");
        require(net.hostAddress != address(0), "Invalid host address");
        require(net.pricePerSession > 0, "Price must be greater than 0");
        require(bytes(net.mongoDataId).length > 0, "MongoDataID required");

        bool isNewNetwork = !networkExists[id];
        
        networks[id] = Network({
            id: net.id,
            hostAddress: net.hostAddress,
            pricePerSession: net.pricePerSession,
            mongoDataId: net.mongoDataId,
            isActive: net.isActive,
            createdAt: isNewNetwork ? block.timestamp : networks[id].createdAt,
            updatedAt: block.timestamp
        });

        if (isNewNetwork) {
            networkExists[id] = true;
            hostNetworkIds[net.hostAddress].push(id);
            emit NetworkStored(id, net.hostAddress, net.pricePerSession);
        } else {
            emit NetworkUpdated(id, net.hostAddress);
        }
    }

    function getNetwork(uint256 id) external view returns (Network memory) {
        require(networkExists[id], "Network does not exist");
        return networks[id];
    }

    function getNetworksPaginated(
        uint256 offset, 
        uint256 limit
    ) external view returns (Network[] memory, uint256 total) {
        require(limit <= MAX_NETWORKS_PER_QUERY, "Limit too high");
        
        total = networkIdCounter;
        if (offset >= total) {
            return (new Network[](0), total);
        }

        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }

        Network[] memory result = new Network[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = networks[i + 1]; // Networks start at ID 1
        }

        return (result, total);
    }

    function getHostNetworks(address hostAddress) external view returns (uint256[] memory) {
        return hostNetworkIds[hostAddress];
    }

    // --- Session Functions ---
    function incrementSessionId() external onlyAllowed returns (uint256) {
        return ++sessionIdCounter;
    }

    function setSession(uint256 id, Session calldata session) external onlyAllowed {
        require(id > 0, "Invalid session ID");
        require(session.paymentAddress != address(0), "Invalid payment address");
        require(session.amount > 0, "Amount must be greater than 0");
        require(networkExists[session.networkId], "Network does not exist");

        sessions[id] = session;
        sessionExists[id] = true;
        emit SessionStored(id, session.paymentAddress, session.amount);
    }

    function getSession(uint256 id) external view returns (Session memory) {
        require(sessionExists[id], "Session does not exist");
        return sessions[id];
    }

    // --- Earnings ---
    function increaseHostEarnings(address hostAddress, uint256 amount) external onlyAllowed nonReentrant {
        require(hostAddress != address(0), "Invalid host address");
        require(amount > 0, "Amount must be greater than 0");
        
        hostEarnings[hostAddress] += amount;
        emit HostEarningsUpdated(hostAddress, hostEarnings[hostAddress]);
    }

    function getHostEarnings(address hostAddress) external view returns (uint256) {
        return hostEarnings[hostAddress];
    }

    // --- Admin Functions ---
    function getStats() external view returns (
        uint256 totalNetworks,
        uint256 totalSessions,
        uint256 activeNetworks,
        uint256 activeSessions
    ) {
        totalNetworks = networkIdCounter;
        totalSessions = sessionIdCounter;

        // Count active networks and sessions
        for (uint256 i = 1; i <= networkIdCounter; i++) {
            if (networks[i].isActive) {
                activeNetworks++;
            }
        }

        for (uint256 i = 1; i <= sessionIdCounter; i++) {
            if (sessions[i].active) {
                activeSessions++;
            }
        }
    }

    // Emergency function to deactivate a network
    function emergencyDeactivateNetwork(uint256 networkId) external onlyOwner {
        require(networkExists[networkId], "Network does not exist");
        networks[networkId].isActive = false;
        networks[networkId].updatedAt = block.timestamp;
        emit NetworkUpdated(networkId, networks[networkId].hostAddress);
    }
}