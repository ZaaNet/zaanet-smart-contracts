// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../ZaaNetStorage.sol";

/// @title IZaaNetPayment - Interface for ZaaNet Payment Contract
interface IZaaNetPayment {
    // ========== Events ==========

    /// @notice Emitted when a session starts
    event SessionStarted(
        uint256 indexed sessionId,
        uint256 indexed networkId,
        address indexed guest,
        uint256 duration,
        uint256 amount,
        bool active
    );

    /// @notice Emitted when payment is received
    event PaymentReceived(
        uint256 indexed sessionId,
        uint256 indexed networkId,
        address indexed guest,
        uint256 amount,
        uint256 platformFee
    );

    // ========== Payment Management ==========

    /// @notice Accept a guest's payment to access a hosted network
    /// @param _networkId The ID of the network being accessed
    /// @param _amount Total amount paid (pricePerHour * duration)
    /// @param _duration Number of hours the guest wants access
    function acceptPayment(
        uint256 _networkId,
        uint256 _amount,
        uint256 _duration
    ) external;

    /// @notice Fetch session details by ID
    /// @param _sessionId The session ID to retrieve
    /// @return The full session object from storage
    function getSession(
        uint256 _sessionId
    ) external view returns (ZaaNetStorage.Session memory);
}
