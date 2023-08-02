import { ethers } from "hardhat";

async function main() {
  // Deployer
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();

  // NRGY
  const NRGY = await ethers.getContractFactory("NRGY");
  const nrgyContract = await NRGY.deploy();
  await nrgyContract.deployed();

  const baseURI = "https://example.com/api/mr/";
  const MRNft = await ethers.getContractFactory("MRNft");
  const mr = await MRNft.deploy(baseURI, deployerAddress);

  const mrReferral = await ethers.getContractFactory("MRReferral");
  const MRReferralContract = await mrReferral.deploy(mr.address, deployerAddress, nrgyContract.address);
  await MRReferralContract.deployed();

  console.log(`MR Referral contract deployed to ${MRReferralContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
