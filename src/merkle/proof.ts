import { ethers } from "ethers";
import getClosestBlock from "../utils/block";

const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

// Users in whitelist
const whiteListed = [
  { user: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8", factor: 250 },
  { user: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", factor: 250 },
  { user: "0x90F79bf6EB2c4f870365E785982E1f101E93b906", factor: 250 },
];

const leaves = whiteListed.map((x) => {
  return keccak256(ethers.utils.solidityPack(["address", "uint256"], [x.user, x.factor]));
});
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

const root = "0x" + tree.getRoot().toString("hex");

// The root hash used to set merkle root in smart contract
console.log("Root Hash", root);

const hexProof = tree.getHexProof(keccak256(ethers.utils.solidityPack(["address", "uint256"], ["0x90f79bf6eb2c4f870365e785982e1f101e93b906", 250])));

// Proof needed to prove that the address is in the white list
// Used in smart contract
console.log("Proof", hexProof);

getClosestBlock(1692100000, "ethereum").then((block) => {
  console.log(block);
});
