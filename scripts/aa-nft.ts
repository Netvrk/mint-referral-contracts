import { ethers } from "hardhat";

async function main() {
  const nrgyAddress = "0x9DFD626221C2A88d38253dd90b09521DBa00108d";
  const AaNft = await ethers.getContractFactory("AaNft");
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  const nftContract = await AaNft.deploy("https://example.com/aa/", deployerAddress, deployerAddress, nrgyAddress);

  await nftContract.deployed();

  console.log(`AaNft deployed to ${nftContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
