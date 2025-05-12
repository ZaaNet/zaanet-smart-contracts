// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ZaaNetStorage.sol";

contract ZaaNetAdmin is Ownable, Pausable {
    ZaaNetStorage public storageContract;
    address public treasury;
    uint256 public platformFeePercent;

    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event AdminPaused(address indexed triggeredBy);
    event AdminUnpaused(address indexed triggeredBy);

    constructor(
        address _storageContract,
        address _treasury,
        uint256 _platformFeePercent
    ) Ownable(msg.sender) {
        storageContract = ZaaNetStorage(_storageContract);
        treasury = _treasury;
        platformFeePercent = _platformFeePercent;
    }

    function setPlatformFee(uint256 _newFeePercent) external onlyOwner {
        require(_newFeePercent <= 20, "Fee cannot exceed 20%");
        emit PlatformFeeUpdated(platformFeePercent, _newFeePercent);
        platformFeePercent = _newFeePercent;
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Invalid treasury address");
        emit TreasuryUpdated(treasury, _newTreasury);
        treasury = _newTreasury;
    }

    function pause() external onlyOwner {
        _pause();
        emit AdminPaused(msg.sender);
    }

    function unpause() external onlyOwner {
        _unpause();
        emit AdminUnpaused(msg.sender);
    }
}

