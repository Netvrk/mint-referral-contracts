import { ethers } from "hardhat";

async function main() {
  const nrgyAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const AaNft = await ethers.getContractFactory("AaNft");
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  const nftContract = await AaNft.deploy("https://example.com/", deployerAddress, deployerAddress, nrgyAddress);

  await nftContract.deployed();

  console.log(`AaNft deployed to ${nftContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
