import dotenv from "dotenv";
import { ethers } from "ethers";

import aaAbi from "./abis/aa.json";
dotenv.config();

const GOERLI_URL = process.env.GOERLI_URL || "https://rpc.ankr.com/goerli";
const MANAGER_PRIVATE_KEY = process.env.MANAGER_PRIVATE_KEY || "";

const goerliProvider = new ethers.providers.JsonRpcProvider(GOERLI_URL, {
  name: "goerli",
  chainId: 5,
});

const manager = new ethers.Wallet(MANAGER_PRIVATE_KEY, goerliProvider);

const referralContracts = {
  aa: new ethers.Contract("0x7DB065902Ac1637fB28937Bf2F10E2F40F882716", aaAbi, manager),
};

export { goerliProvider, referralContracts };
