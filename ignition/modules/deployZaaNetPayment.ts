// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ZaaNetPaymentModule = buildModule("ZaaNetPaymentModule", (m) => {

  // Define the addresses for the contracts
  const usdtContractAddress = "0xBD3822E1949DD2E187da0c3a0F8585f60D512D91";
  const zaanetStorageAddress = "0xfaDf74Cd52Ca7ea500ECcAD6967700bd8Ba88898";
  const adminContractAddress = "0x63a04DB5538c2F994b6102e588b37b4C708aebC1";

  const zaaNetPayment = m.contract("ZaaNetPayment", [
    usdtContractAddress,
    zaanetStorageAddress,
    adminContractAddress,
  ]);

  return { zaaNetPayment };
});

export default ZaaNetPaymentModule;
