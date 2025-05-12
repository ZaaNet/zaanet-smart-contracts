// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IZaaNetAdmin - Interface for ZaaNet Admin Contract
interface IZaaNetAdmin {
    /// @notice Set a new platform fee percentage (in basis points, e.g. 1000 = 10%)
    /// @param _newFeePercent The new platform fee percentage (max 2000 = 20%)
    function setPlatformFee(uint256 _newFeePercent) external;

    /// @notice Set the treasury address that receives platform fees
    /// @param _newTreasury Address of the new treasury
    function setTreasury(address _newTreasury) external;

    /// @notice Pause the platform (via the Admin contract)
    function pause() external;

    /// @notice Unpause the platform (via the Admin contract)
    function unpause() external;

    /// @notice Get the current platform fee percentage
    /// @return The platform fee percentage
    function platformFeePercent() external view returns (uint256);

    /// @notice Get the current treasury address
    /// @return The treasury wallet address
    function treasury() external view returns (address);

    /// @notice Get the address of the contract owner
    /// @return The owner's address
    function owner() external view returns (address);

    /// @notice Returns whether the contract is currently paused
    /// @return True if paused, false otherwise
    function paused() external view returns (bool);
}
