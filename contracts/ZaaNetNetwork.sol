// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ZaaNetStorage.sol";
import "./interface/IZaaNetNetwork.sol";

contract ZaaNetNetwork is Pausable, IZaaNetNetwork {
    ZaaNetStorage public storageContract;
    address public owner;

    mapping(address => bool) public isHost;
    mapping(address => uint256[]) private hostNetworks;

    constructor(address _storageContract) {
        storageContract = ZaaNetStorage(_storageContract);
        owner = msg.sender;
    }

    // Only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    /// @notice Register a new network with metadataCID stored on IPFS
    function registerNetwork(
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external override whenNotPaused {
        require(_pricePerHour > 0, "Price must be greater than 0");
        require(bytes(_metadataCID).length > 0, "Metadata CID required");

        // Request a new ID from storage (calls onlyAllowed internally)
        uint256 networkId = storageContract.incrementNetworkId();

        // Save the network details into storage
        storageContract.setNetwork(
            networkId,
            ZaaNetStorage.Network({
                id: networkId,
                host: msg.sender,
                price: _pricePerHour,
                metadataCID: _metadataCID,
                isActive: _isActive,
                totalRating: 0,
                ratingCount: 0,
                successfulSessions: 0
            })
        );

        hostNetworks[msg.sender].push(networkId);

        if (!isHost[msg.sender]) {
            isHost[msg.sender] = true;
            emit HostAdded(msg.sender);
        }

        emit NetworkRegistered(networkId, msg.sender, _metadataCID);
    }

    /// @notice Update existing network with new metadataCID or price
    function updateNetwork(
        uint256 _networkId,
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external override whenNotPaused {
        ZaaNetStorage.Network memory network = storageContract.getNetwork(
            _networkId
        );
        require(network.id != 0, "Network does not exist");
        require(network.host == msg.sender, "Only host can update");

        storageContract.setNetwork(
            _networkId,
            ZaaNetStorage.Network({
                id: _networkId,
                host: msg.sender,
                price: _pricePerHour,
                metadataCID: _metadataCID,
                isActive: _isActive,
                totalRating: network.totalRating,
                ratingCount: network.ratingCount,
                successfulSessions: network.successfulSessions
            })
        );

        emit NetworkUpdated(_networkId, msg.sender, _metadataCID, _isActive);
    }

    /// @notice Get full network details from storage
    function getHostedNetworkById(
        uint256 _networkId
    ) external view override returns (ZaaNetStorage.Network memory) {
        ZaaNetStorage.Network memory stored = storageContract.getNetwork(
            _networkId
        );
        require(stored.id != 0, "Network does not exist");
        return stored;
    }

    /// @notice Get all network IDs registered by a host
    function getHostNetworks(
        address host
    ) external view returns (uint256[] memory) {
        return hostNetworks[host];
    }

    /// @notice Public method to check if an address is a registered host
    function isRegisteredHost(address account) external view returns (bool) {
        return isHost[account];
    }

    /// @notice Rate a network (1 to 5 stars)
    function rateNetwork(uint256 networkId, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(
            !storageContract.hasRated(msg.sender, networkId),
            "Already rated"
        );

        ZaaNetStorage.Network memory net = storageContract.getNetwork(
            networkId
        );
        require(net.id != 0, "Network not found");

        net.totalRating += rating;
        net.ratingCount += 1;

        storageContract.setNetwork(networkId, net);
        storageContract.markRated(msg.sender, networkId);
    }

    /// @notice Calculate average rating (scaled by 100)
    function getAverageRating(
        uint256 networkId
    ) external view returns (uint256) {
        ZaaNetStorage.Network memory n = storageContract.getNetwork(networkId);
        if (n.ratingCount == 0) return 0;
        return (n.totalRating * 100) / n.ratingCount; // e.g. returns 431 for 4.31
    }

    /// @notice Retrieve all registered networks from storage
    function getAllNetworks()
        external
        view
        returns (ZaaNetStorage.Network[] memory)
    {
        uint256 total = storageContract.networkIdCounter();
        ZaaNetStorage.Network[]
            memory allNetworks = new ZaaNetStorage.Network[](total);

        for (uint256 i = 1; i <= total; i++) {
            allNetworks[i - 1] = storageContract.getNetwork(i);
        }

        return allNetworks;
    }
}
