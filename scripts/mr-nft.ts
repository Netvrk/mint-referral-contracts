import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();

  const baseURI = "https://example.com/api/mr/";

  const MRNft = await ethers.getContractFactory("MRNft");

  const mr = await MRNft.deploy(baseURI, deployerAddress);

  await mr.deployed();

  console.log(`AaNft deployed to ${mr.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
