// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ZaaNetStorage.sol";
import "./interface/IZaaNetNetwork.sol";

contract ZaaNetNetwork is Ownable, Pausable, ReentrancyGuard, IZaaNetNetwork {
    ZaaNetStorage public storageContract;

    // Constants for validation
    uint256 public constant MIN_PRICE_PER_SESSION = 1e18; // 1 USDT (18 decimals for test USDT) 
    uint256 public constant MAX_PRICE_PER_SESSION = 10e18; // 10 USDT (18  decimals for test USDT)
    uint256 public constant MAX_MONGO_DATA_LENGTH = 200; // Reasonable limit for data ID

    mapping(address => bool) public isHost;
    mapping(address => uint256[]) private hostNetworks;
    mapping(uint256 => address) public networkToHost; // For quick lookups

    // Rate limiting
    mapping(address => uint256) public lastRegistrationTime;
    uint256 public constant REGISTRATION_COOLDOWN = 1 minutes;

    constructor(address _storageContract) Ownable(msg.sender) {
        require(
            _storageContract != address(0),
            "Invalid storage contract address"
        );
        storageContract = ZaaNetStorage(_storageContract);

        // CRITICAL: Set this contract as an allowed caller
        storageContract.setAllowedCaller(address(this), true);
    }

    /// @notice Register a new network with mongoDataID
    function registerNetwork(
        uint256 _pricePerHour,
        string memory _mongoDataId,
        bool _isActive
    ) external override whenNotPaused nonReentrant {
        require(
            block.timestamp >=
                lastRegistrationTime[msg.sender] + REGISTRATION_COOLDOWN,
            "Registration cooldown active"
        );
        require(
            _pricePerHour >= MIN_PRICE_PER_SESSION &&
                _pricePerHour <= MAX_PRICE_PER_SESSION,
            "Price out of allowed range"
        );
        require(
            bytes(_mongoDataId).length > 0 &&
                bytes(_mongoDataId).length <= MAX_MONGO_DATA_LENGTH,
            "Invalid MongoDataID length"
        );

        // Request a new ID from storage
        uint256 networkId = storageContract.incrementNetworkId();

        // Save the network details into storage
        storageContract.setNetwork(
            networkId,
            ZaaNetStorage.Network({
                id: networkId,
                hostAddress: msg.sender,
                pricePerSession: _pricePerHour,
                mongoDataId: _mongoDataId,
                isActive: _isActive,
                createdAt: block.timestamp,
                updatedAt: block.timestamp
            })
        );

        hostNetworks[msg.sender].push(networkId);
        networkToHost[networkId] = msg.sender;
        lastRegistrationTime[msg.sender] = block.timestamp;

        if (!isHost[msg.sender]) {
            isHost[msg.sender] = true;
            emit HostAdded(msg.sender);
        }

        emit NetworkRegistered(networkId, msg.sender, _mongoDataId);
    }

    /// @notice Internal function to update network details
    function _updateNetwork(
        uint256 _networkId,
        uint256 _pricePerHour,
        bool _isActive,
        address sender
    ) internal {
        ZaaNetStorage.Network memory network = storageContract.getNetwork(
            _networkId
        );
        require(network.hostAddress == sender, "Only host can update");
        require(
            _pricePerHour >= MIN_PRICE_PER_SESSION &&
                _pricePerHour <= MAX_PRICE_PER_SESSION,
            "Price out of allowed range"
        );

        // Store old values for events
        uint256 oldPrice = network.pricePerSession;
        bool oldStatus = network.isActive;

        storageContract.setNetwork(
            _networkId,
            ZaaNetStorage.Network({
                id: _networkId,
                hostAddress: sender,
                pricePerSession: _pricePerHour,
                mongoDataId: network.mongoDataId, // Keep existing metadata
                isActive: _isActive,
                createdAt: network.createdAt, // Keep original creation time
                updatedAt: block.timestamp
            })
        );

        // Emit detailed events for better tracking
        if (oldPrice != _pricePerHour) {
            emit NetworkPriceUpdated(_networkId, oldPrice, _pricePerHour);
        }
        if (oldStatus != _isActive) {
            emit NetworkStatusChanged(_networkId, oldStatus, _isActive);
        }

        emit NetworkUpdated(
            _networkId,
            sender,
            _pricePerHour,
            network.mongoDataId,
            _isActive
        );
    }

    /// @notice Update existing network with new details
    function updateNetwork(
        uint256 _networkId,
        uint256 _pricePerHour,
        bool _isActive
    ) external override whenNotPaused nonReentrant {
        _updateNetwork(_networkId, _pricePerHour, _isActive, msg.sender);
    }

    /// @notice Deactivate a network (soft delete)
    function deactivateNetwork(uint256 _networkId) external whenNotPaused {
        ZaaNetStorage.Network memory network = storageContract.getNetwork(
            _networkId
        );
        require(network.hostAddress == msg.sender, "Only host can deactivate");
        require(network.isActive, "Network already inactive");

        _updateNetwork(_networkId, network.pricePerSession, false, msg.sender);
    }

    /// @notice Get full network details from storage
    function getHostedNetworkById(
        uint256 _networkId
    ) external view override returns (ZaaNetStorage.Network memory) {
        return storageContract.getNetwork(_networkId);
    }

    /// @notice Get all network IDs registered by a host
    function getHostNetworks(
        address hostAddress
    ) external view override returns (uint256[] memory) {
        return hostNetworks[hostAddress];
    }

    /// @notice Get active networks for a host
    function getActiveHostNetworks(
        address hostAddress
    ) external view returns (ZaaNetStorage.Network[] memory) {
        uint256[] memory networkIds = hostNetworks[hostAddress];
        uint256 activeCount = 0;

        // First pass: count active networks
        for (uint256 i = 0; i < networkIds.length; i++) {
            ZaaNetStorage.Network memory network = storageContract.getNetwork(
                networkIds[i]
            );
            if (network.isActive) {
                activeCount++;
            }
        }

        // Second pass: populate active networks
        ZaaNetStorage.Network[]
            memory activeNetworks = new ZaaNetStorage.Network[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < networkIds.length; i++) {
            ZaaNetStorage.Network memory network = storageContract.getNetwork(
                networkIds[i]
            );
            if (network.isActive) {
                activeNetworks[index] = network;
                index++;
            }
        }

        return activeNetworks;
    }

    /// @notice Public method to check if an address is a registered host
    function isRegisteredHost(
        address hostAddress
    ) external view override returns (bool) {
        return isHost[hostAddress];
    }

    /// @notice Get host statistics
    function getHostStats(
        address hostAddress
    )
        external
        view
        returns (
            uint256 totalNetworks,
            uint256 activeNetworks,
            uint256 totalEarnings
        )
    {
        totalNetworks = hostNetworks[hostAddress].length;
        totalEarnings = storageContract.getHostEarnings(hostAddress);

        // Count active networks
        uint256[] memory networkIds = hostNetworks[hostAddress];
        for (uint256 i = 0; i < networkIds.length; i++) {
            ZaaNetStorage.Network memory network = storageContract.getNetwork(
                networkIds[i]
            );
            if (network.isActive) {
                activeNetworks++;
            }
        }
    }

    /// @notice Retrieve networks with pagination (gas-optimized)
    function getNetworksPaginated(
        uint256 offset, // starting index
        uint256 limit // max number of networks to return (up to 100 for gas efficiency)
    )
        external
        view
        returns (ZaaNetStorage.Network[] memory networks, uint256 totalCount)
    {
        return storageContract.getNetworksPaginated(offset, limit);
    }

    /// @notice Get all active networks (limited to prevent gas issues)
    function getAllActiveNetworks()
        external
        view
        returns (ZaaNetStorage.Network[] memory)
    {
        (ZaaNetStorage.Network[] memory allNetworks, ) = storageContract
            .getNetworksPaginated(0, 100);

        // Count active networks first
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allNetworks.length; i++) {
            if (allNetworks[i].isActive) {
                activeCount++;
            }
        }

        // Array of active networks
        ZaaNetStorage.Network[]
            memory activeNetworks = new ZaaNetStorage.Network[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allNetworks.length; i++) {
            if (allNetworks[i].isActive) {
                activeNetworks[index] = allNetworks[i];
                index++;
            }
        }

        return activeNetworks;
    }

    // --- Admin Functions ---

    /// @notice Emergency pause (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get contract statistics
    function getContractStats() external view returns (uint256 totalNetworks) {
        // This is an approximation - for exact counts, would need to iterate
        totalNetworks = storageContract.networkIdCounter();
    }
}
