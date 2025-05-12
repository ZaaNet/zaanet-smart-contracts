// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaaNetNetworkModule = buildModule("ZaaNetNetworkModule", (m) => {

const zaanetStorageAddress = "0xfaDf74Cd52Ca7ea500ECcAD6967700bd8Ba88898";

  const zaaNetNetwork = m.contract("ZaaNetNetwork", [zaanetStorageAddress]);

  return { zaaNetNetwork };
});

export default ZaaNetNetworkModule;
