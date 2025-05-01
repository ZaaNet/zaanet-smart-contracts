// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ZaaNetStorage.sol";
import "./IZaaNetNetwork.sol";

contract ZaaNetNetwork is Pausable, IZaaNetNetwork {
    ZaaNetStorage public storageContract;

    constructor(address _storageContract) {
        storageContract = ZaaNetStorage(_storageContract);
    }

    function registerNetwork(
        string memory _name,
        string memory _country,
        string memory _city,
        string memory _area,
        uint256 _pricePerHour,
        string memory _metadataCID,
        bool _isActive
    ) external override whenNotPaused {
        require(_pricePerHour > 0, "Price must be greater than 0");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_city).length > 0, "City cannot be empty");

        uint256 networkId = storageContract.incrementNetworkId();

        storageContract.setNetwork(
            networkId,
            ZaaNetStorage.Network({
                id: networkId,
                host: msg.sender,
                name: _name,
                country: _country,
                city: _city,
                area: _area,
                price: _pricePerHour,
                metadataCID: _metadataCID,
                isActive: _isActive,
                totalRating: 0,
                ratingCount: 0,
                successfulSessions: 0
            })
        );

        emit NetworkRegistered(
            networkId,
            msg.sender,
            _name,
            _city,
            _area,
            _metadataCID
        );
    }

    function updateNetwork(
        uint256 _networkId,
        string memory _name,
        string memory _country,
        string memory _city,
        string memory _area,
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
                name: _name,
                country: _country,
                city: _city,
                area: _area,
                price: _pricePerHour,
                metadataCID: _metadataCID,
                isActive: _isActive,
                totalRating: network.totalRating,
                ratingCount: network.ratingCount,
                successfulSessions: network.successfulSessions
            })
        );

        emit NetworkUpdated(
            _networkId,
            msg.sender,
            _name,
            _city,
            _area,
            _metadataCID,
            _isActive
        );
    }

    function getHostedNetworkById(uint256 _networkId)
    external
    view
    override
    returns (IZaaNetNetwork.Network memory)
{
    ZaaNetStorage.Network memory stored = storageContract.getNetwork(_networkId);

    require(stored.id != 0, "Network does not exist");

    // Map from IZaaNetStorage.Network to IZaaNetNetwork.Network
    IZaaNetNetwork.Network memory result = IZaaNetNetwork.Network({
        id: stored.id,
        host: stored.host,
        name: stored.name,
        country: stored.country,
        city: stored.city,
        area: stored.area,
        price: stored.price,
        metadataCID: stored.metadataCID,
        isActive: stored.isActive,
        totalRating: stored.totalRating,
        ratingCount: stored.ratingCount,
        successfulSessions: stored.successfulSessions
    });

    return result;
}


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

    function getAverageRating(
        uint256 networkId
    ) external view returns (uint256) {
        ZaaNetStorage.Network memory n = storageContract.getNetwork(networkId);
        if (n.ratingCount == 0) return 0;
        return (n.totalRating * 100) / n.ratingCount; // returns 431 for 4.31
    }
}
