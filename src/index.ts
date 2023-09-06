import { readSnapshotFromS3, updateSnapshotToS3 } from "./pool/db";
import { generateSnapshot } from "./pool/snapshot";
import { referralContracts } from "./utils/contracts";
async function main() {
  try {
    await snapshot();
  } catch (err) {
    console.error(err);
  }
}

// Step 1
const readSnapshot = async (snapshotName: string) => {
  try {
    const recordsData = await readSnapshotFromS3(snapshotName);
    return recordsData;
  } catch (err) {
    throw new Error("Error in snapshot update, " + err);
  }
};

// Step 2
const snapshotGeneration = async (snapshotName: string, retry = 3) => {
  try {
    console.log("Generating new snapshot");
    const recordsData = await generateSnapshot(false, snapshotName);
    console.log("Snapshot generated");
    return recordsData;
  } catch (err) {
    if (retry === 0) throw new Error("Error in snapshot generation, " + err);
    console.log("Error in snapshot generation", err);
    console.log("Retrying snapshot generation after 1 minute", "Attempt", 4 - retry);
    await new Promise((resolve) => setTimeout(resolve, 60000));
    await snapshotGeneration(snapshotName, retry - 1);
  }
};

// Step 3
const updateSnapshot = async (snapshotRecords: any) => {
  try {
    await updateSnapshotToS3(snapshotRecords);
  } catch (err) {
    throw new Error("Error in snapshot update, " + err);
  }
};

// Step 4
const updateMerkleRoot = async (merkleRoot: string, snapshotName: string, retry = 3) => {
  try {
    // Date to timestamp
    const timestamp = Math.floor(new Date(snapshotName).getTime() / 1000);

    const referralContract = referralContracts["aa"];

    const latestMerkleRoot = await (async function () {
      try {
        return await referralContract.getLatestMerkleRoot();
      } catch (err) {
        return null;
      }
    })();

    console.log("Latest merkle root", latestMerkleRoot);

    if (latestMerkleRoot !== merkleRoot) {
      console.log("Updating merkle root", merkleRoot);
      console.log("Timestamp used", timestamp);
      const tx = await referralContract.updateMerkleRoot(timestamp, merkleRoot);
      console.log("Merkle root updated", tx.hash);
    } else {
      console.log("Merkle root is up to date");
    }
  } catch (err) {
    if (retry === 0) throw new Error("Error in merkle root update, " + err);
    console.log("Error in merkle root update", err);
    console.log("Retrying merkle root update after 1 minute", "Attempt", 4 - retry);
    await new Promise((resolve) => setTimeout(resolve, 60000));
    await updateMerkleRoot(merkleRoot, snapshotName, retry - 1);
  }
};

async function snapshot() {
  try {
    const dateToday = new Date().toISOString().split("T")[0];
    let recordsData = await readSnapshot(dateToday);
    if (!recordsData) {
      recordsData = await snapshotGeneration(dateToday);
      await updateSnapshot(recordsData);
    } else {
      console.log("Snapshot already exists");
    }
    // Update merkle root
    const merkleRoot = recordsData.root;
    await updateMerkleRoot(merkleRoot, dateToday);
  } catch (err) {
    console.log(err);
    process.exit(1);
  }
}

main();
