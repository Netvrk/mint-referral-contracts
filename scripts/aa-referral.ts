import { ethers } from "hardhat";

async function main() {
  // Deployer
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();

  // NRGY
  const NRGY = await ethers.getContractFactory("NRGY");
  const nrgyContract = await NRGY.deploy();
  await nrgyContract.deployed();

  // AaNFT
  const AaNft = await ethers.getContractFactory("AaNft");
  const nftContract = await AaNft.deploy("https://example.com/", deployerAddress, deployerAddress, nrgyContract.address);

  const aaReferral = await ethers.getContractFactory("AaReferral");
  const AaReferralContract = await aaReferral.deploy(nftContract.address, deployerAddress, nrgyContract.address);
  await AaReferralContract.deployed();

  console.log(`NFT deployed to ${AaReferralContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
