import { ethers } from "hardhat";

async function main() {
  const baseURI = "https://example.com/api/rootNft/";
  const RootNft = await ethers.getContractFactory("RootNft");
  const rootNft = await RootNft.deploy("Land", "LAND", baseURI);

  await rootNft.deployed();

  console.log(`AaNft deployed to ${rootNft.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
