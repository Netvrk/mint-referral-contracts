import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { MrNft, MrReferral, NRGY } from "../typechain-types";

describe("MR Referral Contracts test", function () {
  let nftContract: MrNft;
  let nrgyContract: NRGY;
  let mrReferralContract: MrReferral;

  let owner: Signer;
  let user: Signer;
  let user2: Signer;
  let treasury: Signer;
  let ownerAddress: string;
  let userAddress: string;
  let user2Address: string;
  let treasuryAddress: string;

  let now: number;

  before(async function () {
    [owner, user, user2, treasury] = await ethers.getSigners();
    ownerAddress = await owner.getAddress();
    userAddress = await user.getAddress();
    user2Address = await user2.getAddress();
    treasuryAddress = await treasury.getAddress();

    now = await time.latest();
  });

  describe("Deployments", async function () {
    it("Deploy NRGY", async function () {
      // Deploy Token
      const NRGY = await ethers.getContractFactory("NRGY");
      nrgyContract = await NRGY.deploy();
      await nrgyContract.deployed();
    });

    // Deploy NFT
    it("Deploy MR NFT", async function () {
      const baseURI = "https://example.com/api/mr/";
      const NFT = await ethers.getContractFactory("MrNft");
      nftContract = await NFT.deploy(baseURI, ownerAddress);
      await nftContract.deployed();
    });

    // Deploy MrReferral
    it("Deploy MR Referral", async function () {
      const mrReferral = await ethers.getContractFactory("MrReferral");
      mrReferralContract = await mrReferral.deploy(nftContract.address, treasuryAddress, nrgyContract.address);
      await mrReferralContract.deployed();
    });
  });

  describe("Provide manager role and add allowance", async function () {
    it("Shouldn't mint", async function () {
      await expect(mrReferralContract.referralMint(user2Address, "1", "basic", ethers.utils.parseEther("100").toString(), userAddress)).to.be
        .reverted;
    });

    it("Provide manager role", async function () {
      await nftContract.grantRole(await nftContract.MANAGER_ROLE(), mrReferralContract.address);
    });

    it("Check manager role", async function () {
      const hasRole = await nftContract.hasRole(await nftContract.MANAGER_ROLE(), mrReferralContract.address);
      expect(hasRole).to.equal(true);
    });

    it("Add allowance", async function () {
      await nrgyContract.approve(mrReferralContract.address, ethers.utils.parseEther("2000").toString());
    });
  });

  describe("Mint some nfts", async function () {
    it("Mint nfts", async function () {
      await nftContract.mintItem(userAddress, "1", "basic");
    });
  });

  describe("Referral Mint", async function () {
    it("Before MrReferral Mint: Check user balance", async function () {
      const balance = await nrgyContract.balanceOf(userAddress);
      expect(balance).to.equal(0);
    });

    it("Test MrReferral with valid referer", async function () {
      await mrReferralContract.referralMint(user2Address, "2", "basic", ethers.utils.parseEther("100").toString(), userAddress);
    });

    it("After MrReferral Mint:Check user balance", async function () {
      const balance = await nrgyContract.balanceOf(userAddress);
      const balanceParsed = ethers.utils.formatEther(balance);
      expect(balanceParsed).to.equal("25.0");
    });

    it("Test MrReferral with invalid referer", async function () {
      await expect(
        mrReferralContract.referralMint(userAddress, "3", "basic", ethers.utils.parseEther("100").toString(), ownerAddress)
      ).to.be.revertedWith("INVALID_REFERER");
    });
  });

  describe("Withdraw", async function () {
    let contractBalance: string;
    it("Before withdraw: Check treasury balance", async function () {
      const balance = await nrgyContract.balanceOf(treasuryAddress);
      expect(balance).to.equal(0);
    });

    it("Withdraw funds to treasury", async function () {
      contractBalance = ethers.utils.formatEther(await nrgyContract.balanceOf(mrReferralContract.address));
      await mrReferralContract.withdraw();
    });

    it("After withdraw: Check treasury balance", async function () {
      const balance = ethers.utils.formatEther(await nrgyContract.balanceOf(treasuryAddress));
      expect(balance).to.equal(contractBalance);
    });
  });
});
