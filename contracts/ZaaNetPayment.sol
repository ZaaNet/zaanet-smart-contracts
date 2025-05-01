// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ZaaNetStorage.sol";
import "./interface/IZaaNetPayment.sol";

contract ZaaNetPayment is Pausable, IZaaNetPayment {
    IERC20 public usdt;
    ZaaNetStorage public storageContract;
    address public treasury;
    uint256 public platformFeePercent;
    uint256 public constant FEE_DENOMINATOR = 10000;

    constructor(address _usdt, address _storageContract, address _treasury, uint256 _platformFeePercent) {
        usdt = IERC20(_usdt);
        storageContract = ZaaNetStorage(_storageContract);
        treasury = _treasury;
        platformFeePercent = _platformFeePercent;
    }

    function acceptPayment(
        uint256 _networkId,
        uint256 _amount,
        uint256 _duration
    ) external override whenNotPaused {
        ZaaNetStorage.Network memory network = storageContract.getNetwork(_networkId);
        require(network.id != 0, "Network does not exist");
        require(network.isActive, "Network is not active");
        require(_duration > 0 && _duration <= 24 * 3600, "Duration must be 1-24 hours");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 expectedAmount = (network.price * _duration) / 3600;
        require(_amount == expectedAmount, "Incorrect payment amount");

        uint256 platformFee = (_amount * platformFeePercent) / FEE_DENOMINATOR;
        uint256 hostAmount = _amount - platformFee;

        require(usdt.transferFrom(msg.sender, treasury, platformFee), "Platform fee transfer failed");
        require(usdt.transferFrom(msg.sender, network.host, hostAmount), "Host payment transfer failed");

        uint256 sessionId = storageContract.incrementSessionId();
        storageContract.setSession(sessionId, ZaaNetStorage.Session({
            sessionId: sessionId,
            networkId: _networkId,
            guest: msg.sender,
            duration: _duration,
            amount: _amount,
            active: true
        }));

        emit SessionStarted(sessionId, _networkId, msg.sender, _duration, _amount, true);
        emit PaymentReceived(sessionId, _networkId, msg.sender, _amount, platformFee);
    }

    function getSession(uint256 _sessionId) external view override returns (ZaaNetStorage.Session memory) {
        ZaaNetStorage.Session memory session = storageContract.getSession(_sessionId);
        require(session.sessionId != 0, "Session does not exist");
        return session;
    }
}