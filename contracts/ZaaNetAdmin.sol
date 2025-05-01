// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./ZaaNetStorage.sol";
import "./interface/IZaaNetAdmin.sol";

contract ZaaNetAdmin is Ownable, Pausable, IZaaNetAdmin {
    ZaaNetStorage public storageContract;
    address public treasury;
    uint256 public platformFeePercent;

    constructor(address _storageContract, address _treasury, uint256 _platformFeePercent) Ownable(msg.sender) {
        storageContract = ZaaNetStorage(_storageContract);
        treasury = _treasury;
        platformFeePercent = _platformFeePercent;
    }

    function setPlatformFee(uint256 _newFeePercent) external override onlyOwner {
        require(_newFeePercent <= 2000, "Fee cannot exceed 20%");
        platformFeePercent = _newFeePercent;
    }

    function setTreasury(address _newTreasury) external override onlyOwner {
        require(_newTreasury != address(0), "Invalid treasury address");
        treasury = _newTreasury;
    }

    function pause() external override onlyOwner {
        storageContract; // Reference to prevent unused variable warning
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }
}