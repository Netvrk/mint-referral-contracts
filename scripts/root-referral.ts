import { ethers } from "hardhat";

async function main() {
  // Deployer
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();

  // NRGY
  const NRGY = await ethers.getContractFactory("NRGY");
  const nrgyContract = await NRGY.deploy();
  await nrgyContract.deployed();

  const baseURI = "https://example.com/api/rootNft/";
  const RootNft = await ethers.getContractFactory("RootNft");
  const rootNft = await RootNft.deploy("Land", "LAND", baseURI);
  await rootNft.deployed();

  const rootReferral = await ethers.getContractFactory("RootReferral");
  const rootReferralContract = await rootReferral.deploy(rootNft.address, deployerAddress, nrgyContract.address);
  await rootReferralContract.deployed();

  console.log(`MR Referral contract deployed to ${rootReferralContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
