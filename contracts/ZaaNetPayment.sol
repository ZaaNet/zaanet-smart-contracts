// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IZaaNetStorage {
    struct Network {
        uint256 id;
        address hostAddress;
        uint256 pricePerSession;
        string mongoDataId;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function getNetwork(
        uint256 networkId
    ) external view returns (Network memory);

    function increaseHostEarnings(address host, uint256 amount) external;

    function increaseZaaNetEarnings(uint256 amount) external;

   function updateTotalPaymentsAmount(uint256 amount) external;

    function updateTotalWithdrawalsAmount(uint256 amount) external;

    function updateTotalHostingAmount(uint256 amount) external;
}

interface IZaaNetAdmin {
    function platformFeePercent() external view returns (uint256);

    function treasuryAddress() external view returns (address);

    function paymentAddress() external view returns (address);
}

contract ZaaNetPayment is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public usdt;
    uint8 public tokenDecimals;

    IZaaNetStorage public storageContract;
    IZaaNetAdmin public adminContract;

    struct BatchPayment {
        uint256 contractId;
        uint256 grossAmount;
        bytes32 voucherId;
    }

    // Security controls
    uint256 public constant MAX_INDIVIDUAL_PAYMENT = 50 * (10 ** 6); // 50 USDT

    uint256 public constant MAX_FEERATE_PERCENT = 20; // 20% maximum

    // Daily withdrawal limits
    uint256 public dailyWithdrawalLimit = 10000 * (10 ** 6); // 10K USDT
    mapping(uint256 => uint256) public dailyWithdrawals; // day => amount withdrawn

    // Payment validation
    mapping(bytes32 => bool) public processedVouchers; // Prevent double processing

    // Events
    event PaymentProcessed(
        bytes32 indexed voucherId,
        uint256 indexed contractId,
        address indexed host,
        address payer,
        uint256 grossAmount,
        uint256 platformFee,
        uint256 hostAmount,
        uint256 timestamp
    );

    event DailyLimitExceeded(
        address indexed treasury,
        uint256 attemptedAmount,
        uint256 dailyLimit,
        uint256 alreadyWithdrawn
    );

    event BatchPaymentProcessed(
        uint256 batchSize,
        uint256 totalAmount,
        uint256 totalPlatformFee
    );

    // Modifiers
    modifier onlyTreasuryOrOwner() {
        address treasury = adminContract.treasuryAddress();
        require(
            msg.sender == owner() ||
                (treasury != address(0) && msg.sender == treasury),
            "Not authorized"
        );
        _;
    }

    modifier withinDailyLimit(uint256 amount) {
        uint256 today = block.timestamp / 1 days;
        uint256 newDailyTotal = dailyWithdrawals[today] + amount;

        if (newDailyTotal > dailyWithdrawalLimit) {
            emit DailyLimitExceeded(
                msg.sender,
                amount,
                dailyWithdrawalLimit,
                dailyWithdrawals[today]
            );
            require(false, "Daily withdrawal limit exceeded");
        }

        dailyWithdrawals[today] = newDailyTotal;
        _;
    }

    constructor(
        address _usdt,
        address _storageContract,
        address _adminContract
    ) Ownable(msg.sender) {
        require(_usdt != address(0), "token zero");
        require(_storageContract != address(0), "storage zero");
        require(_adminContract != address(0), "admin zero");

        usdt = IERC20(_usdt);
        tokenDecimals = IERC20Metadata(_usdt).decimals();

        storageContract = IZaaNetStorage(_storageContract);
        adminContract = IZaaNetAdmin(_adminContract);
    }

    /**
     * @notice Process a payment for a voucher with enhanced security controls
     * @param _contractId The ID of the network contract
     * @param _grossAmount The total amount paid by the user (in USDT, 6 decimals)
     * @param _voucherId Unique voucher ID to prevent double processing
     * @dev Enforces max individual payment, daily limits, and prevents double processing
     */
    function processPayment(
        uint256 _contractId,
        uint256 _grossAmount,
        bytes32 _voucherId
    ) external whenNotPaused nonReentrant withinDailyLimit(_grossAmount) {
        // Only payment address can call this
        require(
            msg.sender == adminContract.paymentAddress(),
            "Not payment address"
        );

        // Prevent double processing
        require(!processedVouchers[_voucherId], "Voucher already processed");

        // Validate individual payment against MAX_INDIVIDUAL_PAYMENT
        require(
            _grossAmount > 0 && _grossAmount <= MAX_INDIVIDUAL_PAYMENT,
            "Invalid amount"
        );

        // Validate network
        IZaaNetStorage.Network memory network = storageContract.getNetwork(
            _contractId
        );
        require(network.isActive, "Network not active");
        require(_grossAmount >= network.pricePerSession, "Amount too low");

        // Get platform fee
        uint256 feePercent = adminContract.platformFeePercent();
        require(feePercent <= MAX_FEERATE_PERCENT, "Fee too high");

        // Get treasury address
        address treasuryWallet = adminContract.treasuryAddress();
        require(treasuryWallet != address(0), "Invalid treasury");

        // Get payment address
        address paymentWallet = adminContract.paymentAddress();
        require(paymentWallet != address(0), "Invalid payment");
        require(msg.sender == paymentWallet, "Not payment address");

        // Process normal payment
        _executePayment(
            _contractId,
            _grossAmount,
            _voucherId,
            network,
            feePercent,
            treasuryWallet
        );
    }

    /**
     * @notice Process a batch of payments for vouchers with enhanced security controls
     * @dev Limits: max 50 payments per batch, total batch amount must not exceed daily limit
     * @param payments Array of BatchPayment structs
     */
    function processBatchPayments(
        BatchPayment[] calldata payments
    ) external whenNotPaused nonReentrant {
        // Only payment address can call this
        require(
            msg.sender == adminContract.paymentAddress(),
            "Not payment address"
        );
        require(
            payments.length > 0 && payments.length <= 50,
            "Invalid batch size"
        );

        uint256 totalAmount = 0;
        uint256 feePercent = adminContract.platformFeePercent();
        require(feePercent <= MAX_FEERATE_PERCENT, "Fee too high");

        address treasuryWallet = adminContract.treasuryAddress();
        require(treasuryWallet != address(0), "Invalid treasury");

        // First pass: validate all payments and calculate total
        for (uint256 i = 0; i < payments.length; i++) {
            BatchPayment memory payment = payments[i];

            // Basic validations
            require(
                payment.grossAmount > 0 &&
                    payment.grossAmount <= MAX_INDIVIDUAL_PAYMENT,
                "Invalid amount"
            );
            require(
                !processedVouchers[payment.voucherId],
                "Voucher already processed"
            );

            // Validate network
            IZaaNetStorage.Network memory network = storageContract.getNetwork(
                payment.contractId
            );
            require(network.isActive, "Network not active");
            require(
                payment.grossAmount >= network.pricePerSession,
                "Amount too low"
            );

            totalAmount += payment.grossAmount;
        }

        // Check daily limit for total batch
        require(totalAmount <= getRemainingDailyLimit(), "Exceeds daily limit");

        // Update daily withdrawals
        uint256 today = block.timestamp / 1 days;
        dailyWithdrawals[today] += totalAmount;

        // Check contract balance
        require(
            usdt.balanceOf(address(this)) >= totalAmount,
            "Insufficient contract balance"
        );

        // Second pass: execute all payments
        uint256 totalPlatformFee = 0;

        for (uint256 i = 0; i < payments.length; i++) {
            BatchPayment memory payment = payments[i];

            IZaaNetStorage.Network memory network = storageContract.getNetwork(
                payment.contractId
            );

            uint256 platformFee = (payment.grossAmount * feePercent) / 100;
            uint256 hostAmount = payment.grossAmount - platformFee;

            // Transfer to host
            usdt.safeTransfer(network.hostAddress, hostAmount);

            // Update earnings
            storageContract.increaseHostEarnings(
                network.hostAddress,
                hostAmount
            );

            totalPlatformFee += platformFee;


            // Mark as processed to prevent double-processing
            processedVouchers[payment.voucherId] = true;

            // Emit individual event
            emit PaymentProcessed(
                payment.voucherId,
                payment.contractId,
                network.hostAddress,
                msg.sender,
                payment.grossAmount,
                platformFee,
                hostAmount,
                block.timestamp
            );
        }

        // Transfer total platform fees
        if (totalPlatformFee > 0) {
            usdt.safeTransfer(treasuryWallet, totalPlatformFee);
            storageContract.increaseZaaNetEarnings(totalPlatformFee);
        }

        // Update total payments amount in storage
        storageContract.updateTotalPaymentsAmount(totalAmount);

        emit BatchPaymentProcessed(
            payments.length,
            totalAmount,
            totalPlatformFee
        );
    }

    /**
     * @notice Internal function to execute payment
     * @param _contractId The ID of the network contract
     * @param _grossAmount The total amount paid by the user (in USDT, 6 decimals)
     * @param _voucherId Unique voucher ID to prevent double processing
     * @param network The network details from storage
     * @param feePercent The platform fee percentage
     * @param treasuryWallet The treasury wallet address
     * @dev Assumes all validations are done prior to calling this function
     */
    function _executePayment(
        uint256 _contractId,
        uint256 _grossAmount,
        bytes32 _voucherId,
        IZaaNetStorage.Network memory network,
        uint256 feePercent,
        address treasuryWallet
    ) internal {
        // Mark voucher as processed
        processedVouchers[_voucherId] = true;

        // Calculate fee and host share
        uint256 platformFee = (_grossAmount * feePercent) / 100;
        uint256 hostAmount = _grossAmount - platformFee;

        // Final balance check
        require(
            usdt.balanceOf(address(this)) >= hostAmount + platformFee,
            "Insufficient contract balance for payment"
        );

        // Transfer host payment
        usdt.safeTransfer(network.hostAddress, hostAmount);

        // Transfer platform fee
        if (platformFee > 0) {
            usdt.safeTransfer(treasuryWallet, platformFee);
        }

        // Update storage
        storageContract.increaseHostEarnings(network.hostAddress, hostAmount);
        if (platformFee > 0) {
            storageContract.increaseZaaNetEarnings(platformFee);
        }

        // Update total payments amount in storage
        storageContract.updateTotalPaymentsAmount(_grossAmount);

        emit PaymentProcessed(
            _voucherId,
            _contractId,
            network.hostAddress,
            msg.sender,
            _grossAmount,
            platformFee,
            hostAmount,
            block.timestamp
        );
    }

    /**
     * @notice Set daily withdrawal limit (owner only)
     */
    function setDailyWithdrawalLimit(uint256 _newLimit) external onlyOwner {
        require(_newLimit > 0, "Invalid limit");
        dailyWithdrawalLimit = _newLimit;
    }

    /**
     * @notice Get today's withdrawal amount
     */
    function getTodayWithdrawals() external view returns (uint256) {
        uint256 today = block.timestamp / 1 days;
        return dailyWithdrawals[today];
    }

    /**
     * @notice Check if voucher has been processed
     */
    function isVoucherProcessed(
        bytes32 _voucherId
    ) external view returns (bool) {
        return processedVouchers[_voucherId];
    }

    /**
     * @notice Get remaining daily limit
     */
    function getRemainingDailyLimit() public view returns (uint256) {
        uint256 today = block.timestamp / 1 days;
        uint256 used = dailyWithdrawals[today];
        return used >= dailyWithdrawalLimit ? 0 : dailyWithdrawalLimit - used;
    }

    // Existing functions remain the same...
    function withdrawToken(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");
        require(usdt.balanceOf(address(this)) >= _amount, "Insufficient contract balance");
        require(_amount <= getRemainingDailyLimit(), "Exceeds daily withdrawal limit");
        usdt.safeTransfer(_to, _amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function rescueERC20(
        address _erc20,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "zero to");
        IERC20(_erc20).safeTransfer(_to, _amount);
    }

    function contractTokenBalance() external view returns (uint256) {
        return usdt.balanceOf(address(this));
    }
}
