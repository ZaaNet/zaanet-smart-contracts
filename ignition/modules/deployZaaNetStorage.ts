// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaaNetStorageModule = buildModule("ZaaNetStorageModule", (m) => {

  const zaaNetStorage = m.contract("ZaaNetStorage");

  return { zaaNetStorage };
});

export default ZaaNetStorageModule;
