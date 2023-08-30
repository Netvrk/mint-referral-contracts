import { ethers } from "ethers";
import keccak256 from "keccak256";

export async function getProof(tree: any, user: string, factor: number) {
  const hexProof = tree.getHexProof(keccak256(ethers.utils.solidityPack(["address", "uint256"], [user, factor])));
  return hexProof;
}
