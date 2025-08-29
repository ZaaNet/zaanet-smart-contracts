// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ZaaNetStorage.sol";

contract ZaaNetAdmin is Ownable, Pausable, ReentrancyGuard {
    ZaaNetStorage public storageContract;
    address public treasuryAddress; // Address to receive platform fees
    address public paymentAddress; // Address to make voucher payments
    uint256 public platformFeePercent; // Platform fee percentage (1-20%)
    uint256 public hostingFee; // Hosting fee in USDT (6 decimals)

    // Constants for validation
    uint256 public constant MAX_PLATFORM_FEE = 20; // 20% maximum fee
    uint256 public constant MIN_PLATFORM_FEE = 1;  // 1% minimum fee
    uint256 public constant MAX_HOSTING_FEE = 100 * (10 ** 6); // 100 USDT maximum hosting fee
    uint256 public constant MIN_HOSTING_FEE = 0; // 0 USDT minimum hosting fee (can be free)

    // Emergency controls
    bool public emergencyMode = false;
    mapping(address => bool) public emergencyOperators;

    // Fee history for transparency
    struct FeeChange {
        uint256 oldFee;
        uint256 newFee;
        uint256 timestamp;
        address changedBy;
    }
    
    FeeChange[] public feeHistory;
    
    // Treasury change history
    struct TreasuryChange {
        address oldTreasury;
        address newTreasury;
        uint256 timestamp;
        address changedBy;
    }
    
    TreasuryChange[] public treasuryHistory;

    // Hosting fee history
    struct HostingFeeChange {
        uint256 oldFee;
        uint256 newFee;
        uint256 timestamp;
        address changedBy;
    }
    
    HostingFeeChange[] public hostingFeeHistory;

    // Events
    event PlatformFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee, address indexed changedBy);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury, address indexed changedBy);
    event HostingFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee, address indexed changedBy);
    event AdminPaused(address indexed triggeredBy);
    event AdminUnpaused(address indexed triggeredBy);
    event EmergencyModeToggled(bool enabled, address indexed triggeredBy);
    event EmergencyOperatorUpdated(address indexed operator, bool status, address indexed updatedBy);
    event ContractsInitialized(address indexed storageContract, uint256 timestamp);

    modifier onlyEmergencyOperator() {
        require(emergencyOperators[msg.sender] || msg.sender == owner(), "Not emergency operator");
        _;
    }

    modifier notInEmergencyMode() {
        require(!emergencyMode, "System in emergency mode");
        _;
    }

    constructor(
        address _storageContract,
        address _treasuryAddress,
        address _paymentAddress,
        uint256 _platformFeePercent,
        uint256 _hostingFee
    ) Ownable(msg.sender) {
        require(_treasuryAddress != address(0), "Treasury cannot be zero address");
        require(
            _platformFeePercent >= MIN_PLATFORM_FEE && _platformFeePercent <= MAX_PLATFORM_FEE, 
            "Platform fee must be between 1% and 20%"
        );
        require(_paymentAddress != address(0), "Payment address cannot be zero address");
        require(
            _hostingFee >= MIN_HOSTING_FEE && _hostingFee <= MAX_HOSTING_FEE,
            "Hosting fee must be between 0 and 100 USDT"
        );

        if (_storageContract != address(0)) {
            storageContract = ZaaNetStorage(_storageContract);
            emit ContractsInitialized(_storageContract, block.timestamp);
        }
        
        treasuryAddress = _treasuryAddress;
        platformFeePercent = _platformFeePercent;
        hostingFee = _hostingFee;

        // Record initial settings
        feeHistory.push(FeeChange({
            oldFee: 0,
            newFee: _platformFeePercent,
            timestamp: block.timestamp,
            changedBy: msg.sender
        }));

        treasuryHistory.push(TreasuryChange({
            oldTreasury: address(0),
            newTreasury: _treasuryAddress,
            timestamp: block.timestamp,
            changedBy: msg.sender
        }));

        hostingFeeHistory.push(HostingFeeChange({
            oldFee: 0,
            newFee: _hostingFee,
            timestamp: block.timestamp,
            changedBy: msg.sender
        }));

        // Set owner as emergency operator
        emergencyOperators[msg.sender] = true;
        emit EmergencyOperatorUpdated(msg.sender, true, msg.sender);
    }

    function setPlatformFee(uint256 _newFeePercent) external onlyOwner notInEmergencyMode {
        require(
            _newFeePercent >= MIN_PLATFORM_FEE && _newFeePercent <= MAX_PLATFORM_FEE, 
            "Fee must be between 1% and 20%"
        );
        require(_newFeePercent != platformFeePercent, "Fee unchanged");

        uint256 oldFee = platformFeePercent;
        platformFeePercent = _newFeePercent;

        // Record fee change
        feeHistory.push(FeeChange({
            oldFee: oldFee,
            newFee: _newFeePercent,
            timestamp: block.timestamp,
            changedBy: msg.sender
        }));

        emit PlatformFeeUpdated(oldFee, _newFeePercent, msg.sender);
    }

    function setHostingFee(uint256 _newFee) external onlyOwner notInEmergencyMode {
        require(
            _newFee >= MIN_HOSTING_FEE && _newFee <= MAX_HOSTING_FEE,
            "Fee must be between 0 and 100 USDT"
        );
        require(_newFee != hostingFee, "Fee unchanged");
        
        uint256 oldFee = hostingFee;
        hostingFee = _newFee;
        
        // Record hosting fee change
        hostingFeeHistory.push(HostingFeeChange({
            oldFee: oldFee,
            newFee: _newFee,
            timestamp: block.timestamp,
            changedBy: msg.sender
        }));
        
        emit HostingFeeUpdated(oldFee, _newFee, msg.sender);
    }

    function setTreasuryAddress(address _newTreasuryAddress) external onlyOwner notInEmergencyMode {
        require(_newTreasuryAddress != address(0), "Invalid treasury address");
        require(_newTreasuryAddress != treasuryAddress, "Treasury unchanged");

        address oldTreasury = treasuryAddress;
        treasuryAddress = _newTreasuryAddress;

        // Record treasury change
        treasuryHistory.push(TreasuryChange({
            oldTreasury: oldTreasury,
            newTreasury: _newTreasuryAddress,
            timestamp: block.timestamp,
            changedBy: msg.sender
        }));

        emit TreasuryUpdated(oldTreasury, _newTreasuryAddress, msg.sender);
    }

    function setPaymentAddress(address _newPaymentAddress) external onlyOwner notInEmergencyMode {
        require(_newPaymentAddress != address(0), "Invalid payment address");
        require(_newPaymentAddress != paymentAddress, "Payment address unchanged");

        paymentAddress = _newPaymentAddress;
    }

    function pause() external onlyOwner {
        _pause();
        emit AdminPaused(msg.sender);
    }

    function unpause() external onlyOwner {
        _unpause();
        emit AdminUnpaused(msg.sender);
    }

    /// @notice Toggle emergency mode (stops most operations)
    function toggleEmergencyMode() external onlyEmergencyOperator {
        emergencyMode = !emergencyMode;
        emit EmergencyModeToggled(emergencyMode, msg.sender);
    }

    /// @notice Add or remove emergency operators
    function setEmergencyOperator(address operator, bool status) external onlyOwner {
        require(operator != address(0), "Invalid operator address");
        emergencyOperators[operator] = status;
        emit EmergencyOperatorUpdated(operator, status, msg.sender);
    }

    /// @notice Emergency function to deactivate a network
    function emergencyDeactivateNetwork(uint256 networkId) external onlyEmergencyOperator {
        require(address(storageContract) != address(0), "Storage not initialized");
        storageContract.emergencyDeactivateNetwork(networkId);
    }

    /// @notice Emergency fee adjustment (bypasses normal restrictions)
    function emergencySetPlatformFee(uint256 _newFeePercent) external onlyEmergencyOperator {
        require(_newFeePercent <= MAX_PLATFORM_FEE, "Fee cannot exceed maximum");
        
        uint256 oldFee = platformFeePercent;
        platformFeePercent = _newFeePercent;

        feeHistory.push(FeeChange({
            oldFee: oldFee,
            newFee: _newFeePercent,
            timestamp: block.timestamp,
            changedBy: msg.sender
        }));

        emit PlatformFeeUpdated(oldFee, _newFeePercent, msg.sender);
    }

    /// @notice Emergency hosting fee adjustment (bypasses normal restrictions)
    function emergencySetHostingFee(uint256 _newFee) external onlyEmergencyOperator {
        require(_newFee <= MAX_HOSTING_FEE, "Fee cannot exceed maximum");
        
        uint256 oldFee = hostingFee;
        hostingFee = _newFee;

        hostingFeeHistory.push(HostingFeeChange({
            oldFee: oldFee,
            newFee: _newFee,
            timestamp: block.timestamp,
            changedBy: msg.sender
        }));

        emit HostingFeeUpdated(oldFee, _newFee, msg.sender);
    }

    // --- View Functions ---

    /// @notice Expose admin address for other contracts (interface compatibility)
    function admin() external view returns (address) {
        return owner();
    }

    /// @notice Get fee change history
    function getFeeHistory() external view returns (FeeChange[] memory) {
        return feeHistory;
    }

    /// @notice Get treasury change history
    function getTreasuryHistory() external view returns (TreasuryChange[] memory) {
        return treasuryHistory;
    }

    /// @notice Get hosting fee change history
    function getHostingFeeHistory() external view returns (HostingFeeChange[] memory) {
        return hostingFeeHistory;
    }

    /// @notice Get current fee in basis points (for more precise calculations)
    function getPlatformFeeBasisPoints() external view returns (uint256) {
        return platformFeePercent * 100; // Convert percentage to basis points
    }   

    /// @notice Calculate platform fee for a given amount
    function calculatePlatformFee(uint256 amount) external view returns (uint256) {
        return (amount * platformFeePercent) / 100;
    }

    /// @notice Get comprehensive admin statistics
    function getAdminStats() external view returns (
        uint256 totalFeeChanges,
        uint256 totalTreasuryChanges,
        uint256 totalHostingFeeChanges,
        bool isEmergencyMode,
        uint256 currentPlatformFee,
        uint256 currentHostingFee,
        address currentTreasury
    ) {
        totalFeeChanges = feeHistory.length;
        totalTreasuryChanges = treasuryHistory.length;
        totalHostingFeeChanges = hostingFeeHistory.length;
        isEmergencyMode = emergencyMode;
        currentPlatformFee = platformFeePercent;
        currentHostingFee = hostingFee;
        currentTreasury = treasuryAddress;
    }

    /// @notice Check if address is emergency operator
    function isEmergencyOperator(address operator) external view returns (bool) {
        return emergencyOperators[operator];
    }

    /// @notice Get latest fee change details
    function getLatestFeeChange() external view returns (FeeChange memory) {
        require(feeHistory.length > 0, "No fee changes recorded");
        return feeHistory[feeHistory.length - 1];
    }

    /// @notice Get latest treasury change details
    function getLatestTreasuryChange() external view returns (TreasuryChange memory) {
        require(treasuryHistory.length > 0, "No treasury changes recorded");
        return treasuryHistory[treasuryHistory.length - 1];
    }

    /// @notice Get latest hosting fee change details
    function getLatestHostingFeeChange() external view returns (HostingFeeChange memory) {
        require(hostingFeeHistory.length > 0, "No hosting fee changes recorded");
        return hostingFeeHistory[hostingFeeHistory.length - 1];
    }

    /// @notice Get all current fees in one call (gas efficient)
    function getCurrentFees() external view returns (
        uint256 platformFeePercentage,
        uint256 hostingFeeAmount,
        address treasury
    ) {
        return (platformFeePercent, hostingFee, treasuryAddress);
    }

    // --- Compatibility Functions (for interface alignment) ---

    /// @notice Alternative name for treasury address (interface compatibility)
    function treasury() external view returns (address) {
        return treasuryAddress;
    }

    /// @notice Check if contract is paused (interface compatibility)
    function paused() public view override returns (bool) {
        return super.paused();
    }
}