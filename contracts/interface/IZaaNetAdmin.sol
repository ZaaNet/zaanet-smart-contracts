// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IZaaNetAdmin - Interface for ZaaNet Admin Contract
interface IZaaNetAdmin {

    // ========== Admin Functions ==========

    function setPlatformFee(uint256 _newFeePercent) external;

    function setTreasuryAddress(address _newTreasury) external;

    function pause() external;

    function unpause() external;

    function toggleEmergencyMode() external;

    // ========== View Functions ==========

    function platformFeePercent() external view returns (uint256);

    function treasuryAddress() external view returns (address);

    /// @notice Alternative name for treasuryAddress (compatibility)
    function treasury() external view returns (address);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    /// @notice Alternative name for owner (compatibility)
    function admin() external view returns (address);

    function emergencyMode() external view returns (bool);

    function calculatePlatformFee(uint256 amount) external view returns (uint256);
}