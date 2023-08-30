import { ethers } from "ethers";

import keccak256 from "keccak256";
import { MerkleTree } from "merkletreejs";

export function getMerkleTree(snapshotData: any) {
  const leaves = snapshotData.map((x: any) => {
    return keccak256(ethers.utils.solidityPack(["address", "uint256"], [x.user, parseInt(x.factor)]));
  });
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  return tree;
}

export async function getMerkleRoot(snapshotData: any) {
  const tree = getMerkleTree(snapshotData);
  const root = "0x" + tree.getRoot().toString("hex");
  return root;
}
