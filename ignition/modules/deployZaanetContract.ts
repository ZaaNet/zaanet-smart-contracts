// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaanetContractModule = buildModule("ZaanetContractModule", (m) => {

  const zaanet = m.contract("ZaanetContract");

  return { zaanet };
});

export default ZaanetContractModule;
