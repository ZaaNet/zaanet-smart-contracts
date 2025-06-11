// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IZaaNetAdmin - Interface for ZaaNet Admin Contract
interface IZaaNetAdmin {
    function setPlatformFee(uint256 _newFeePercent) external;

    function setTreasury(address _newTreasury) external;

    function pause() external;

    function unpause() external;

    function platformFeePercent() external view returns (uint256);

    function treasury() external view returns (address);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function admin() external view returns (address); // Optional: allows .admin() usage in Payment contract
}
