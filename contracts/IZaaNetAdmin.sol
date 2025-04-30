// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IZaaNetAdmin {
    function setPlatformFee(uint256 _newFeePercent) external;
    function setTreasury(address _newTreasury) external;
    function pause() external;
    function unpause() external;
}