// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ZaaNetStorage.sol"; 

// Ensure ZaaNetStorage.Session is accessible
using zaaNetStorage for ZaaNetStorage.Session;

interface IZaaNetPayment {
    event SessionStarted(
        uint256 indexed sessionId,
        uint256 indexed networkId,
        address indexed guest,
        uint256 duration,
        uint256 amount,
        bool active
    );
    event PaymentReceived(
        uint256 indexed sessionId,
        uint256 indexed networkId,
        address indexed guest,
        uint256 amount,
        uint256 platformFee
    );

    function acceptPayment(uint256 _networkId, uint256 _amount, uint256 _duration) external;
    function getSession(uint256 _sessionId) external view returns (zaaNetStorage.Session memory);
}