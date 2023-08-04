import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();

  const baseURI = "https://example.com/api/mr/";

  const MrNft = await ethers.getContractFactory("MrNft");

  const mr = await MrNft.deploy(baseURI, deployerAddress);

  await mr.deployed();

  console.log(`MR Nft deployed to ${mr.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
