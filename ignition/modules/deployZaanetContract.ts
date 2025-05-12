// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaaNetContractModule = buildModule("ZaaNetContractModule", (m) => {

  const zaaNetNetworkContractAddress = "0x55836E883D28D117eDe9B1679D56B444b770add7";
  const zaanetPaymentContractAddress = "0x0EAae997E5718936CD659510a8FB60c58b3B17Ae";
  const zaanetAdminContractAddress = "0x63a04DB5538c2F994b6102e588b37b4C708aebC1";

  const zaaNetContract = m.contract("ZaaNetContract", [
    zaaNetNetworkContractAddress,
    zaanetPaymentContractAddress,
    zaanetAdminContractAddress,
  ]);

  return { zaaNetContract };
});

export default ZaaNetContractModule;
