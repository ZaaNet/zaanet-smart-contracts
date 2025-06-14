// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ZaaNetStorage.sol";
import "./interface/IZaaNetPayment.sol";
import "./TestUSDT.sol";
import "./ZaaNetAdmin.sol";

contract ZaaNetPayment is Pausable, IZaaNetPayment {
    TestUSDT public usdt;
    ZaaNetStorage public storageContract;
    ZaaNetAdmin public adminContract;

    constructor(
        address _usdt,
        address _storageContract,
        address _adminContract
    ) {
        require(_usdt != address(0), "Invalid USDT address");
        require(_storageContract != address(0), "Invalid Storage address");
        require(_adminContract != address(0), "Invalid Admin address");

        usdt = TestUSDT(_usdt);
        storageContract = ZaaNetStorage(_storageContract);
        adminContract = ZaaNetAdmin(_adminContract);
    }

    function acceptPayment(
        uint256 _networkId,
        uint256 _amount,
        uint256 _duration
    ) external override whenNotPaused {
        ZaaNetStorage.Network memory network = storageContract.getNetwork(_networkId);
        require(network.id != 0 && network.isActive, "Invalid or inactive network");
        require(_duration > 0 && _duration <= 24, "Duration must be 1-24 hours");
        require(_amount > 0, "Amount must be > 0");

        uint256 expectedAmount = network.price * _duration;
        require(_amount == expectedAmount, "Incorrect payment amount");

        uint256 platformFeePercent = adminContract.platformFeePercent();
        address treasury = adminContract.treasury();

        uint256 platformFee = (_amount * platformFeePercent) / 100;
        uint256 hostAmount = _amount - platformFee;

        require(usdt.transferFrom(msg.sender, treasury, platformFee), "Fee transfer failed");
        require(usdt.transferFrom(msg.sender, network.host, hostAmount), "Host transfer failed");

        storageContract.increaseHostEarnings(network.host, hostAmount);

        uint256 sessionId = storageContract.incrementSessionId();
        storageContract.setSession(
            sessionId,
            ZaaNetStorage.Session({
                sessionId: sessionId,
                networkId: _networkId,
                guest: msg.sender,
                duration: _duration,
                amount: _amount,
                active: true
            })
        );

        emit SessionStarted(sessionId, _networkId, msg.sender, _duration, _amount, true);
        emit PaymentReceived(sessionId, _networkId, msg.sender, _amount, platformFee);
    }

    function getSession(
        uint256 _sessionId
    ) external view override returns (ZaaNetStorage.Session memory) {
        return storageContract.getSession(_sessionId);
    }

    function pause() external {
        require(msg.sender == adminContract.owner(), "Not admin");
        _pause();
    }

    function unpause() external {
        require(msg.sender == adminContract.owner(), "Not admin");
        _unpause();
    }

    /// @notice Helper to calculate fee breakdown before payment
    function calculateFees(
        uint256 pricePerHour,
        uint256 duration
    ) external view returns (uint256 hostAmount, uint256 platformFee) {
        uint256 amount = pricePerHour * duration;
        uint256 fee = (amount * adminContract.platformFeePercent()) / 100;
        return (amount - fee, fee);
    }
}
