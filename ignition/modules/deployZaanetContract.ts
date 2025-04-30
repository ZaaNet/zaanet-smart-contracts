// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaanetContractModule = buildModule("ZaanetContractModule", (m) => {

  const tokenContract = "0xBD3822E1949DD2E187da0c3a0F8585f60D512D91"
  const zaanet = m.contract("ZaanetContract", [tokenContract]);

  return { zaanet };
});

export default ZaanetContractModule;
