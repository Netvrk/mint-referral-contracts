import { ethers } from "hardhat";

async function main() {
  const NRGY = await ethers.getContractFactory("NRGY");
  const nrgyContract = await NRGY.deploy();

  await nrgyContract.deployed();

  console.log(`NRGY Token deployed to ${nrgyContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
