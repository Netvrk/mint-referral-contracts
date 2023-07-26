import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { NFT, NRGY, Referral } from "../typechain-types";

describe("NFT Referral", function () {
  let nftContract: NFT;
  let nrgyContract: NRGY;
  let referralContract: Referral;

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
    it("Deploy NFT", async function () {
      const NFT = await ethers.getContractFactory("NFT");
      nftContract = await NFT.deploy("https://example.com/", ownerAddress, ownerAddress, nrgyContract.address);
      await nftContract.deployed();
    });

    // Deploy Referral
    it("Deploy Referral", async function () {
      const Referral = await ethers.getContractFactory("Referral");
      referralContract = await Referral.deploy(nftContract.address, treasuryAddress, nrgyContract.address);
      await referralContract.deployed();
    });
  });

  describe("Provide minter role and add allowance", async function () {
    it("Shouldn't mint", async function () {
      await expect(referralContract.referralMint(user2Address, 1, 1, ethers.utils.parseEther("100").toString(), userAddress)).to.be.reverted;
    });

    it("Provide minter role", async function () {
      await nftContract.grantRole(await nftContract.MINTER_ROLE(), referralContract.address);
    });

    it("Check minter role", async function () {
      const hasRole = await nftContract.hasRole(await nftContract.MINTER_ROLE(), referralContract.address);
      expect(hasRole).to.equal(true);
    });

    it("Add allowance", async function () {
      await nrgyContract.approve(referralContract.address, ethers.utils.parseEther("2000").toString());
    });
  });

  describe("Initialize tier and mint nfts", async function () {
    it("Initialize tier", async function () {
      await nftContract.initTier(1, ethers.utils.parseEther("100"), 100);
    });

    it("Update Tier Price", async function () {
      await expect(referralContract.referralMint(user2Address, 1, 1, ethers.utils.parseEther("100").toString(), userAddress)).to.be.revertedWith(
        "INVALID_TIER_PRICE"
      );
      await referralContract.updateTierPrice(1, ethers.utils.parseEther("100"));
    });

    it("Mint nfts", async function () {
      await nftContract.bulkMint([userAddress], [1], [5]);
    });
  });

  describe("Referral", async function () {
    it("Before Referral Mint: Check user balance", async function () {
      const balance = await nrgyContract.balanceOf(userAddress);
      expect(balance).to.equal(0);
    });

    it("Test referral with valid referer", async function () {
      await referralContract.referralMint(user2Address, 1, 1, ethers.utils.parseEther("100").toString(), userAddress);
    });

    it("After Referral Mint:Check user balance", async function () {
      const balance = await nrgyContract.balanceOf(userAddress);
      const balanceParsed = ethers.utils.formatEther(balance);
      expect(balanceParsed).to.equal("25.0");
    });

    it("Test referral with invalid referer", async function () {
      await expect(referralContract.referralMint(userAddress, 1, 1, ethers.utils.parseEther("100").toString(), ownerAddress)).to.be.revertedWith(
        "INVALID_REFERER"
      );
    });
  });

  describe("Withdraw", async function () {
    let contractBalance: string;
    it("Before withdraw: Check treasury balance", async function () {
      const balance = await nrgyContract.balanceOf(treasuryAddress);
      expect(balance).to.equal(0);
    });

    it("Withdraw funds to treasury", async function () {
      contractBalance = ethers.utils.formatEther(await nrgyContract.balanceOf(referralContract.address));
      await referralContract.withdraw();
    });

    it("After withdraw: Check treasury balance", async function () {
      const balance = ethers.utils.formatEther(await nrgyContract.balanceOf(treasuryAddress));
      expect(balance).to.equal(contractBalance);
    });
  });
});
