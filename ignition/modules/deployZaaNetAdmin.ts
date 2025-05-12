// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaaNetAdminModule = buildModule("ZaaNetAdminModule", (m) => {

  // Define the addresses for the contracts
  const zaanetStorageAddress = "0xfaDf74Cd52Ca7ea500ECcAD6967700bd8Ba88898";
  const treasuryAddress = "0x2652164707AA3269C83FEAA9923b0e19CacFA906";
  const platformFeePercent = 5;

  const zaaNetAdmin = m.contract("ZaaNetAdmin", [
    zaanetStorageAddress,
    treasuryAddress,
    platformFeePercent,
  ]);

  return { zaaNetAdmin };
});

export default ZaaNetAdminModule;
