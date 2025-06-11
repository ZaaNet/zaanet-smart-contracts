import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaaNetDeploymentModule = buildModule("ZaaNetDeploymentModule", (m) => {
  const testUSDTAddress = "0x1A14a686567945626350481fC07Ec24767d1A640";
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

  // 3. Deploy ZaaNetNetwork
  const zaaNetNetwork = m.contract("ZaaNetNetwork", [zaaNetStorage]);

  // 4. Deploy ZaaNetPayment
  const zaaNetPayment = m.contract("ZaaNetPayment", [
    testUSDTAddress,
    zaaNetStorage,
    zaaNetAdmin,
  ]);

  // 5. Authorize all callers in ZaaNetStorage
  m.call(zaaNetStorage, "setAllowedCaller", [zaaNetNetwork, true], {
    id: "authorizeNetworkCaller",
  });

  m.call(zaaNetStorage, "setAllowedCaller", [zaaNetPayment, true], {
    id: "authorizePaymentCaller",
  });

  m.call(zaaNetStorage, "setAllowedCaller", [zaaNetAdmin, true], {
    id: "authorizeAdminCaller",
  });

  return {
    zaaNetStorage,
    zaaNetAdmin,
    zaaNetNetwork,
    zaaNetPayment,
  };
});

export default ZaaNetDeploymentModule;
