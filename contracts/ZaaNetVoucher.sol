// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ZaaNetStorage.sol";
import "./TestUSDT.sol";

contract ZaaNetVoucher is ReentrancyGuard, Ownable {
    // IERC20 public immutable usdtToken;
        TestUSDT public usdt;

    address public treasuryWallet;
    ZaaNetStorage public zaaNetStorage;
    
    event VoucherPurchased(
        address indexed buyer,
        uint256 indexed networkId,
        uint256 amount,
        uint256 timestamp
    );

    constructor(address _usdtToken, address _treasuryWallet, address _zaaNetStorage) Ownable(msg.sender) {
            // usdtToken = IERC20(_usdtToken);
        usdt = TestUSDT(_usdtToken);
        treasuryWallet = _treasuryWallet;
        zaaNetStorage = ZaaNetStorage(_zaaNetStorage);
    }
    function buyVoucher(
        uint256 networkId,
        uint256 amount,
        address buyer
    ) external nonReentrant {
        // Get the network details from the storage contract
            ZaaNetStorage.Network memory network = zaaNetStorage.getNetwork(
            networkId
        );
        require(network.isActive, "Network is not active");
        require(amount > network.pricePerSession, "Amount must be greater than the price per session");
        require(buyer != address(0), "Invalid buyer address");
        
        require(
            usdt.transferFrom(buyer, treasuryWallet, amount),
            "Transfer failed"
        );
        
        emit VoucherPurchased(buyer, networkId, amount, block.timestamp);
    }
    
    function updateTreasuryWallet(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid address");
        treasuryWallet = newTreasury;
    }
}

