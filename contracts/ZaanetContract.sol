// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract ZaanetContract is ReentrancyGuard, Pausable {
    uint256 public networkIdCounter;
    uint256 public constant MAX_HOSTS = 3;
    uint256 public zaanetFeePercent = 5;
    address public owner;

    struct Location {
        string city;
        string country;
        string area;
        string latitude;
        string longitude;
    }

    struct ZaanetHost {
        uint256 id;
        address hostAddress;
        string name;
        string passwordCID;
        Location location;
        string wifispeed;
        uint256 price;
        string description;
        string imageCID;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct UpdateNetworkParams {
        string name;
        string passwordCID;
        string city;
        string country;
        string area;
        string latitude;
        string longitude;
        string wifispeed;
        uint256 price;
        string description;
        string imageCID;
        bool isActive;
    }

    mapping(address => mapping(uint256 => ZaanetHost))
        public hostedNetworksByAddress;
    mapping(address => uint256[]) public networkIdsByAddress;
    mapping(address => bool) public isHost;
    mapping(uint256 => ZaanetHost) public hostedNetworkById;
    mapping(uint256 => mapping(address => bool)) public hasPaid;
    mapping(uint256 => uint256) public totalEarnedByHostedNetwork;
    mapping(address => uint256) public totalEarnedByAddress;

    event NewNetworkHosted(uint256 id, address hostAddress);
    event HostedNetworkUpdated(uint256 id, address hostAddress);
    event HostDeleted(uint256 id, address hostAddress);
    event PaymentReceived(
        uint256 id,
        address user,
        uint256 amount,
        uint256 timestamp
    );
    event FeePercentUpdated(uint256 newFeePercent);

    constructor() {
        owner = msg.sender;
        networkIdCounter = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function hostANetwork(
        string memory _name,
        string memory _passwordCID,
        string memory _city,
        string memory _country,
        string memory _area,
        string memory _latitude,
        string memory _longitude,
        string memory _wifispeed,
        uint256 _price,
        string memory _description,
        string memory _imageCID
    ) public whenNotPaused {
        require(
            networkIdsByAddress[msg.sender].length < MAX_HOSTS,
            "Max hosts reached"
        );
        require(bytes(_name).length > 0, "Name empty");
        require(bytes(_passwordCID).length > 0, "Password required");
        require(_price > 0, "Price must be greater than 0");

        networkIdCounter++;

        ZaanetHost memory newHost = ZaanetHost({
            id: networkIdCounter,
            hostAddress: msg.sender,
            name: _name,
            passwordCID: _passwordCID,
            location: Location(_city, _country, _area, _latitude, _longitude),
            wifispeed: _wifispeed,
            price: _price,
            description: _description,
            imageCID: _imageCID,
            isActive: true,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        hostedNetworksByAddress[msg.sender][networkIdCounter] = newHost;
        networkIdsByAddress[msg.sender].push(networkIdCounter);
        hostedNetworkById[networkIdCounter] = newHost;
        isHost[msg.sender] = true;

        emit NewNetworkHosted(networkIdCounter, msg.sender);
    }

    function getHostedNetworkById(
        uint256 _id
    ) public view returns (ZaanetHost memory) {
        require(hostedNetworkById[_id].id != 0, "Network not exist");
        return hostedNetworkById[_id];
    }

    function getHostedNetworksByAddress(
        address _host
    ) public view returns (ZaanetHost[] memory) {
        uint256[] memory ids = networkIdsByAddress[_host];
        ZaanetHost[] memory networks = new ZaanetHost[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            networks[i] = hostedNetworksByAddress[_host][ids[i]];
        }
        return networks;
    }

    function getPasswordCID(uint256 _id) public view returns (string memory) {
        require(hostedNetworkById[_id].id != 0, "Network not exist");
        require(hasPaid[_id][msg.sender], "Payment required");
        return hostedNetworkById[_id].passwordCID;
    }

    function updateHostedNetwork(
        uint256 _id,
        UpdateNetworkParams memory params
    ) public whenNotPaused {
        require(hostedNetworkById[_id].id != 0, "Network not exist");
        require(
            hostedNetworkById[_id].hostAddress == msg.sender,
            "You are not the host"
        );
        require(bytes(params.name).length > 0, "Name empty");
        require(bytes(params.passwordCID).length > 0, "Password required");
        require(params.price > 0, "Price can't be 0");

        ZaanetHost storage host = hostedNetworkById[_id];
        host.name = params.name;
        host.passwordCID = params.passwordCID;
        host.location = Location(
            params.city,
            params.country,
            params.area,
            params.latitude,
            params.longitude
        );
        host.wifispeed = params.wifispeed;
        host.price = params.price;
        host.description = params.description;
        host.imageCID = params.imageCID;
        host.updatedAt = block.timestamp;
        host.isActive = params.isActive;

        hostedNetworksByAddress[msg.sender][_id] = host;

        emit HostedNetworkUpdated(host.id, msg.sender);
    }

    function deleteHostedNetwork(uint256 _id) public whenNotPaused {
        ZaanetHost storage host = hostedNetworkById[_id];
        require(host.id != 0, "Network not exist");
        require(host.hostAddress == msg.sender, "Only the host");

        delete hostedNetworkById[_id];
        delete hostedNetworksByAddress[msg.sender][_id];

        uint256[] storage ids = networkIdsByAddress[msg.sender];
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == _id) {
                ids[i] = ids[ids.length - 1];
                ids.pop();
                break;
            }
        }

        if (ids.length == 0) {
            isHost[msg.sender] = false;
        }

        emit HostDeleted(_id, msg.sender);
    }

    function acceptPayment(
        uint256 _id
    ) public payable nonReentrant whenNotPaused {
        ZaanetHost memory host = hostedNetworkById[_id];
        require(host.id != 0, "Network not exist");
        require(host.isActive, "Network not active");
        require(msg.value == host.price, "Incorrect payment amount");

        uint256 fee = (msg.value * zaanetFeePercent) / 100;
        uint256 hostPayment = msg.value - fee;

        hasPaid[_id][msg.sender] = true;
        emit PaymentReceived(_id, msg.sender, msg.value, block.timestamp);

        payable(host.hostAddress).transfer(hostPayment);
        totalEarnedByHostedNetwork[_id] += hostPayment;
        totalEarnedByAddress[host.hostAddress] += hostPayment;
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner).transfer(balance);
    }

    function updateZaanetFeePercent(uint256 _newFeePercent) public onlyOwner {
        require(_newFeePercent <= 100, "Can't exceed 100%");
        require(_newFeePercent >= 1, "Must be atleast 1%");
        zaanetFeePercent = _newFeePercent;
        emit FeePercentUpdated(_newFeePercent);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
