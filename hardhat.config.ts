import { HardhatUserConfig } from "hardhat/config";

import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";
import "@matterlabs/hardhat-zksync-upgradable";

// dynamically changes endpoints for local tests
const zkSyncMainnet =
{
  url: "https://mainnet.era.zksync.io",
  ethNetwork: "mainnet",
  zksync: true,
  verifyURL: "https://zksync2-mainnet-explorer.zksync.io/contract_verification",
}

const config: HardhatUserConfig = {
  zksolc: {
    version: "latest",
    settings: {},
  },
  defaultNetwork: "zkSyncMainnet",
  networks: {
    hardhat: {
      zksync: false,
    },
    // zkSyncTestnet,
    zkSyncMainnet
  },
  solidity: {
    version: "0.8.4",
  },
};

export default config;
