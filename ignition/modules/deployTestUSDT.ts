// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TestUSDTContractModule = buildModule("TestUSDTContractModule", (m) => {

  const testUSDT = m.contract("TestUSDT", [1000000]);

  return { testUSDT };
});

export default TestUSDTContractModule;
