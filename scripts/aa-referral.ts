import { ethers } from "hardhat";

async function main() {
  // Deployer
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();

  /*
  // NRGY
  const NRGY = await ethers.getContractFactory("NRGY");
  const nrgyContract = await NRGY.deploy();
  await nrgyContract.deployed();

  // AaNFT
  const AaNft = await ethers.getContractFactory("AaNft");
  const nftContract = await AaNft.deploy("https://example.com/", deployerAddress, deployerAddress, nrgyContract.address);

  */

  const nrgyContract = {
    address: "0x9DFD626221C2A88d38253dd90b09521DBa00108d",
  };

  const nftContract = {
    address: "0x96694a89BC38982824e8EfB8529ebe661EFDA6f6",
  };

  const aaReferral = await ethers.getContractFactory("AaReferral");
  const AaReferralContract = await aaReferral.deploy(nftContract.address, deployerAddress, nrgyContract.address);
  await AaReferralContract.deployed();

  console.log(`AA Referral contracts deployed to ${AaReferralContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
