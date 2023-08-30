import { ethers } from "ethers";
import * as fs from "fs";
import keccak256 from "keccak256";
import * as path from "path";
import { CsvFile } from "../utils/csv-file";
import { getMerkleTree } from "./root";

export async function getProof(tree: any, user: string, factor: number) {
  const hexProof = tree.getHexProof(keccak256(ethers.utils.solidityPack(["address", "uint256"], [user, factor])));
  return hexProof;
}

export async function getProofFromFile(user: string, factor: number, filename: string = "") {
  const inFile = path.join(__dirname, `../../exports/snapshots/${filename}.csv`);
  if (!fs.existsSync(inFile)) {
    console.log("User snapshot list not found");
    return;
  }

  const readCsvFile = new CsvFile({
    path: inFile,
    headers: ["user", "staked", "unstaked", "total", "factor"],
  });
  const records = await readCsvFile.read();

  const tree = getMerkleTree(records);

  const proof = getProof(tree, user, factor);

  return proof;
}
