// Unified Hardhat Ignition deployment script for all ZaaNet contracts

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaaNetDeploymentModule = buildModule("ZaaNetDeploymentModule", (m) => {
  const testUSDTAddress = "0xBD3822E1949DD2E187da0c3a0F8585f60D512D91";
  const treasuryAddress = "0x2652164707AA3269C83FEAA9923b0e19CacFA906";
  const platformFeePercent = 5;

  // 1. Deploy ZaaNetStorage
  const zaaNetStorage = m.contract("ZaaNetStorage");

  // 2. Deploy ZaaNetAdmin
  const zaaNetAdmin = m.contract("ZaaNetAdmin", [
    zaaNetStorage,
    treasuryAddress,
    platformFeePercent,
  ]);

  // 3. Deploy ZaaNetNetwork with reference to storage
  const zaaNetNetwork = m.contract("ZaaNetNetwork", [zaaNetStorage]);

  // 4. Deploy ZaaNetPayment with reference to USDT, storage, admin
  const zaaNetPayment = m.contract("ZaaNetPayment", [
    testUSDTAddress,
    zaaNetStorage,
    zaaNetAdmin,
  ]);

  // 5. Authorize ZaaNetNetwork and ZaaNetPayment to mutate ZaaNetStorage
  m.call(zaaNetStorage, "setAllowedCaller", [zaaNetNetwork, true], {
    id: "authorizeNetworkCaller",
  });

  m.call(zaaNetStorage, "setAllowedCaller", [zaaNetPayment, true], {
    id: "authorizePaymentCaller",
  });

  return {
    zaaNetStorage,
    zaaNetAdmin,
    zaaNetNetwork,
    zaaNetPayment,
  };
});

export default ZaaNetDeploymentModule;
