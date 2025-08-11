// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ZaaNetStorage.sol";
import "./interface/IZaaNetPayment.sol";
import "./TestUSDT.sol";
import "./ZaaNetAdmin.sol";

contract ZaaNetPayment is Ownable, Pausable, ReentrancyGuard {
    TestUSDT public usdt;
    ZaaNetStorage public storageContract;
    ZaaNetAdmin public adminContract;

    // Constants
    uint256 public constant MAX_PAYMENT_AMOUNT = 10000e18; // 10,000 USDT (for dev testing usdt is 18 decimals)

    /// @notice Emitted when a session starts
    event SessionStarted(
        uint256 indexed sessionId,
        uint256 indexed networkId,
        address indexed paymentAddress,
        uint256 amount,
        bool active,
        string voucherId,
        string userId,
        uint256 startTime
    );

    /// @notice Emitted when payment is received
    event PaymentReceived(
        uint256 indexed sessionId,
        uint256 indexed networkId,
        address indexed paymentAddress,
        uint256 amount,
        uint256 platformFee
    );

    constructor(
        address _usdt,
        address _storageContract,
        address _adminContract
    ) Ownable(msg.sender) {
        require(_usdt != address(0), "Invalid USDT address");
        require(_storageContract != address(0), "Invalid Storage address");
        require(_adminContract != address(0), "Invalid Admin address");

        usdt = TestUSDT(_usdt);
        storageContract = ZaaNetStorage(_storageContract);
        adminContract = ZaaNetAdmin(_adminContract);
    }

    function acceptPayment(
        uint256 _networkId,
        uint256 _amount,
        string memory _voucherId,
        string memory _userId
    ) external whenNotPaused nonReentrant {
        // Validate inputs
        require(
            _amount > 0 && _amount <= MAX_PAYMENT_AMOUNT,
            "Invalid payment amount"
        );

        // Get network and validate
        ZaaNetStorage.Network memory network = storageContract.getNetwork(
            _networkId
        );
        require(network.isActive, "Network is not active");
        require(_amount >= network.pricePerSession, "Payment amount too low");

        // Calculate fees FIRST (checks-effects-interactions pattern)
        uint256 platformFeePercent = adminContract.platformFeePercent();
        address treasuryAddress = adminContract.treasuryAddress();

        require(treasuryAddress != address(0), "Invalid treasury address");
        require(platformFeePercent <= 20, "Platform fee too high");

        uint256 platformFee = (_amount * platformFeePercent) / 100;
        uint256 hostAmount = _amount - platformFee;

        // Create session BEFORE external calls
        uint256 sessionId = storageContract.incrementSessionId();
        storageContract.setSession(
            sessionId,
            ZaaNetStorage.Session({
                sessionId: sessionId,
                networkId: _networkId,
                paymentAddress: msg.sender,
                amount: _amount,
                active: true,
                voucherId: _voucherId,
                userId: _userId,
                startTime: block.timestamp
            })
        );

        // External calls LAST (after all state changes)
        bool feeTransferSuccess = usdt.transferFrom(
            msg.sender,
            treasuryAddress,
            platformFee
        );
        require(feeTransferSuccess, "Platform fee transfer failed");

        bool hostTransferSuccess = usdt.transferFrom(
            msg.sender,
            network.hostAddress,
            hostAmount
        );
        require(hostTransferSuccess, "Host payment transfer failed");

        // Update host earnings
        storageContract.increaseHostEarnings(network.hostAddress, hostAmount);

        emit SessionStarted(
            sessionId,
            _networkId,
            msg.sender,
            _amount,
            true,
            _voucherId,
            _userId,
            block.timestamp
        );

        emit PaymentReceived(
            sessionId,
            _networkId,
            msg.sender,
            _amount,
            platformFee
        );
    }

    function getSession(
        uint256 _sessionId
    ) external view returns (ZaaNetStorage.Session memory) {
        return storageContract.getSession(_sessionId);
    }

    /// @notice Helper to calculate fee breakdown before payment
    function calculateFees(
        uint256 amount
    ) external view returns (uint256 hostAmount, uint256 platformFee) {
        uint256 feePercent = adminContract.platformFeePercent();
        platformFee = (amount * feePercent) / 100;
        hostAmount = amount - platformFee;
        return (hostAmount, platformFee);
    }

    // --- Admin Functions ---

    function pause() external {
        require(
            msg.sender == owner() || msg.sender == adminContract.owner(),
            "Not authorized to pause"
        );
        _pause();
    }

    function unpause() external {
        require(
            msg.sender == owner() || msg.sender == adminContract.owner(),
            "Not authorized to unpause"
        );
        _unpause();
    }

    /// @notice Update USDT contract address (emergency only)
    function updateUSDTAddress(address _newUSDT) external onlyOwner {
        require(_newUSDT != address(0), "Invalid USDT address");
        usdt = TestUSDT(_newUSDT);
    }

    /// @notice Update admin contract address (emergency only)
    function updateAdminContract(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Invalid admin address");
        adminContract = ZaaNetAdmin(_newAdmin);
    }
}
