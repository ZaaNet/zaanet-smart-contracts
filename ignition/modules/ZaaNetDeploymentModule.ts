import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaaNetDeploymentModule = buildModule("ZaaNetDeploymentModule", (m) => {
  // Configuration - Update these addresses as needed
  const testUSDTAddress = "0x1A14a686567945626350481fC07Ec24767d1A640"; // Existing USDT contract
  const treasuryAddress = "0x2652164707AA3269C83FEAA9923b0e19CacFA906";  // Treasury wallet
  const platformFeePercent = 10; // 5% platform fee

  console.log("🚀 Starting ZaaNet deployment with Hardhat Ignition...");
  console.log(`📋 Configuration:`);
  console.log(`   - Test USDT: ${testUSDTAddress}`);
  console.log(`   - Treasury: ${treasuryAddress}`);
  console.log(`   - Platform Fee: ${platformFeePercent}%`);

  // 1. Deploy ZaaNetStorage first (no dependencies)
  const zaaNetStorage = m.contract("ZaaNetStorage", [], {
    id: "ZaaNetStorage",
  });

  // 2. Deploy ZaaNetAdmin (depends on storage)
  const zaaNetAdmin = m.contract("ZaaNetAdmin", [
    zaaNetStorage,
    treasuryAddress,
    platformFeePercent,
  ], {
    id: "ZaaNetAdmin",
  });

  // 3. Deploy ZaaNetNetwork (depends on storage)
  const zaaNetNetwork = m.contract("ZaaNetNetwork", [
    zaaNetStorage,
  ], {
    id: "ZaaNetNetwork",
  });

  // 4. Deploy ZaaNetPayment (depends on USDT, storage, and admin)
  const zaaNetPayment = m.contract("ZaaNetPayment", [
    testUSDTAddress,
    zaaNetStorage,
    zaaNetAdmin,
  ], {
    id: "ZaaNetPayment",
  });

  // 5. Deploy ZaaNetVoucher (depends on USDT, storage and treasury)
  const zaaNetVoucher = m.contract("ZaaNetVoucher", [
    testUSDTAddress,
    treasuryAddress,
    zaaNetStorage,
  ], {
    id: "ZaaNetVoucher",
  });

  // 5. Access control - CRITICAL for functionality
  // Note: These calls will be executed after all contracts are deployed

  // Authorize ZaaNetNetwork to call ZaaNetStorage
  m.call(zaaNetStorage, "setAllowedCaller", [zaaNetNetwork, true], {
    id: "authorizeNetworkCaller",
    after: [zaaNetNetwork], // Ensure network is deployed first
  });

  // Authorize ZaaNetPayment to call ZaaNetStorage  
  m.call(zaaNetStorage, "setAllowedCaller", [zaaNetPayment, true], {
    id: "authorizePaymentCaller", 
    after: [zaaNetPayment], // Ensure payment is deployed first
  });

  // Authorize ZaaNetAdmin to call ZaaNetStorage
  m.call(zaaNetStorage, "setAllowedCaller", [zaaNetAdmin, true], {
    id: "authorizeAdminCaller",
    after: [zaaNetAdmin], // Ensure admin is deployed first
  });

  // Authorize ZaaNetVoucher to call ZaaNetStorage
  m.call(zaaNetStorage, "setAllowedCaller", [zaaNetVoucher, true], {
    id: "authorizeVoucherCaller",
    after: [zaaNetVoucher], // Ensure voucher is deployed first
  });

  // Return all deployed contracts for external reference
  return {
    zaaNetStorage,
    zaaNetAdmin, 
    zaaNetNetwork,
    zaaNetPayment,
    zaaNetVoucher,
  };
});

export default ZaaNetDeploymentModule;