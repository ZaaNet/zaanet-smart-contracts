// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../ZaaNetStorage.sol";

interface IZaaNetContract {
    // Network Management
    function registerNetwork(
        uint256 pricePerHour,
        string memory metadataCID,
        bool isActive
    ) external;

    function updateNetwork(
        uint256 networkId,
        uint256 pricePerHour,
        string memory metadataCID,
        bool isActive
    ) external;

    function getHostedNetworkById(
        uint256 networkId
    ) external view returns (ZaaNetStorage.Network memory);

    // Payments
    function acceptPayment(
        uint256 networkId,
        uint256 amount,
        uint256 duration
    ) external;

    function getSession(
        uint256 sessionId
    ) external view returns (ZaaNetStorage.Session memory);

    // Admin Controls
    function setPlatformFee(uint256 newFeePercent) external;
    function setTreasury(address newTreasury) external;
    function pause() external;
    function unpause() external;

    // Emergency Functions
    function emergencyWithdrawETH(address payable recipient) external;
    function emergencyWithdrawERC20(address token, address recipient, uint256 amount) external;
}
