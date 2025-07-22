// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../ZaaNetStorage.sol";

/// @title IZaaNetPayment - Interface for ZaaNet Payment Contract
interface IZaaNetPayment {
    // ========== Payment Management ==========

    /// @notice Accept a payment to access a hosted network
    /// @param _networkId The ID of the network being accessed
    /// @param _amount Total amount paid (pricePerSession)
    /// @param _voucherId Optional voucher/discount code ID
    /// @param _userId User identifier for tracking
    function acceptPayment(
        uint256 _networkId,
        uint256 _amount,
        uint256 _voucherId,
        uint256 _userId
    ) external;

    /// @notice Fetch session details by ID
    /// @param _sessionId The session ID to retrieve
    /// @return The full session object from storage
    function getSession(
        uint256 _sessionId
    ) external view returns (ZaaNetStorage.Session memory);

    /// @notice Calculate fees for a payment amount
    /// @param amount The payment amount to calculate fees for
    /// @return hostAmount Amount that goes to the host
    /// @return platformFee Amount that goes to the platform
    function calculateFees(
        uint256 amount
    ) external view returns (uint256 hostAmount, uint256 platformFee);
}