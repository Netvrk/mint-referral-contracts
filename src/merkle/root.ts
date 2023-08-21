import { ethers } from "ethers";

import * as fs from "fs";
import * as path from "path";
import { CsvFile } from "../utils/csv-file";

import keccak256 from "keccak256";
import { MerkleTree } from "merkletreejs";

export function getMerkleTree(snapshotData: any) {
  const leaves = snapshotData.map((x: any) => {
    return keccak256(ethers.utils.solidityPack(["address", "uint256"], [x.user, parseInt(x.factor)]));
  });
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  return tree;
}

async function getMerkleRoot(snapshotData: any) {
  const tree = getMerkleTree(snapshotData);
  const root = "0x" + tree.getRoot().toString("hex");
  return root;
}

export async function getMerkleRootFromFile(filename: string = "") {
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

  const root = getMerkleRoot(records);

  return root;
}
