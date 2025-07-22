// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../ZaaNetStorage.sol";

/// @title IZaaNetStorage - Interface for ZaaNet Storage Contract
interface IZaaNetStorage {

    // ========== Access Control ==========
    
    function setAllowedCaller(address _caller, bool status) external;
    function setAllowedCallers(address[] calldata _callers, bool status) external;

    // ========== Network Functions ==========
    
    function incrementNetworkId() external returns (uint256);
    function setNetwork(uint256 id, ZaaNetStorage.Network calldata network) external;
    function getNetwork(uint256 id) external view returns (ZaaNetStorage.Network memory);
    function getNetworksPaginated(uint256 offset, uint256 limit) external view returns (ZaaNetStorage.Network[] memory, uint256 total);
    function networkIdCounter() external view returns (uint256);

    // ========== Session Functions ==========
    
    function incrementSessionId() external returns (uint256);
    function setSession(uint256 id, ZaaNetStorage.Session calldata session) external;
    function getSession(uint256 id) external view returns (ZaaNetStorage.Session memory);
    function endSession(uint256 sessionId) external;
    function sessionIdCounter() external view returns (uint256);

    // ========== Earnings Functions ==========
    
    function increaseHostEarnings(address hostAddress, uint256 amount) external;
    function getHostEarnings(address hostAddress) external view returns (uint256);

    // ========== Admin Functions ==========
    
    function emergencyDeactivateNetwork(uint256 networkId) external;
    function getStats() external view returns (uint256 totalNetworks, uint256 totalSessions, uint256 activeNetworks, uint256 activeSessions);
}