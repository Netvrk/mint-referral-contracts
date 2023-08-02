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
  const MrNft = await ethers.getContractFactory("MrNft");
  const mr = await MrNft.deploy(baseURI, deployerAddress);

  const mrReferral = await ethers.getContractFactory("MrReferral");
  const MrReferralContract = await mrReferral.deploy(mr.address, deployerAddress, nrgyContract.address);
  await MrReferralContract.deployed();

  console.log(`MR Referral contract deployed to ${MrReferralContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
