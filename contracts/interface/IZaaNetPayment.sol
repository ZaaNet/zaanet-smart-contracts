// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../ZaaNetStorage.sol";

// @title IZaaNetPayment - Interface for ZaaNet Payment Contract
interface IZaaNetPayment {
    event SessionStarted(
        uint256 indexed sessionId,
        uint256 indexed networkId,
        address indexed guest,
        uint256 duration,
        uint256 amount,
        bool active
    );

    // ========== Events ==========
    event PaymentReceived(
        uint256 indexed sessionId,
        uint256 indexed networkId,
        address indexed guest,
        uint256 amount,
        uint256 platformFee
    );

    // ========== Payment Management ==========
    function acceptPayment(
        uint256 _networkId,
        uint256 _amount,
        uint256 _duration
    ) external;

    function getSession(
        uint256 _sessionId
    ) external view returns (ZaaNetStorage.Session memory);
}
