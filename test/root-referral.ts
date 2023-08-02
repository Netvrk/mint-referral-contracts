import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { NRGY, RootNft } from "../typechain-types";

describe("Root NFT Contracts test", function () {
  let nftContract: RootNft;
  let nrgyContract: NRGY;
  let rootReferralContract: RootReferral;

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
      const baseURI = "https://example.com/api/nft/";
      const RootNft = await ethers.getContractFactory("RootNft");
      nftContract = await RootNft.deploy("Land", "LAND", baseURI);
      await nftContract.deployed();
    });

    // Deploy Root Referral
    it("Deploy Root Referral", async function () {
      const rootReferral = await ethers.getContractFactory("RootReferral");
      rootReferralContract = await rootReferral.deploy(nftContract.address, treasuryAddress, nrgyContract.address);
      await rootReferralContract.deployed();
    });
  });

  describe("Provide minter role and add allowance", async function () {
    it("Shouldn't mint", async function () {
      await expect(rootReferralContract.referralMint(user2Address, 1, ethers.utils.parseEther("100").toString(), userAddress)).to.be.reverted;
    });

    it("Provide minter role", async function () {
      await nftContract.grantRole(await nftContract.PREDICATE_ROLE(), rootReferralContract.address);
    });

    it("Check minter role", async function () {
      const hasRole = await nftContract.hasRole(await nftContract.PREDICATE_ROLE(), rootReferralContract.address);
      expect(hasRole).to.equal(true);
    });

    it("Add allowance", async function () {
      await nrgyContract.approve(rootReferralContract.address, ethers.utils.parseEther("2000").toString());
    });
  });

  describe("Mint nfts", async function () {
    it("Mint nfts", async function () {
      await nftContract.mint(userAddress, 1);
    });
  });

  describe("Referral mint", async function () {
    it("Before Root Referral Mint: Check user balance", async function () {
      const balance = await nrgyContract.balanceOf(userAddress);
      expect(balance).to.equal(0);
    });

    it("Test Root Referral with valid referer", async function () {
      await rootReferralContract.referralMint(user2Address, 2, ethers.utils.parseEther("100").toString(), userAddress);
    });

    it("After Root Referral Mint:Check user balance", async function () {
      const balance = await nrgyContract.balanceOf(userAddress);
      const balanceParsed = ethers.utils.formatEther(balance);
      expect(balanceParsed).to.equal("25.0");
    });

    it("Test Root Referral with invalid referer", async function () {
      await expect(rootReferralContract.referralMint(userAddress, 3, ethers.utils.parseEther("100").toString(), ownerAddress)).to.be.revertedWith(
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
      contractBalance = ethers.utils.formatEther(await nrgyContract.balanceOf(rootReferralContract.address));
      await rootReferralContract.withdraw();
    });

    it("After withdraw: Check treasury balance", async function () {
      const balance = ethers.utils.formatEther(await nrgyContract.balanceOf(treasuryAddress));
      expect(balance).to.equal(contractBalance);
    });
  });
});
