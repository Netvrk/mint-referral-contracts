import cron from "node-cron";
import { readSnapshotFromS3, updateSnapshotToS3 } from "./pool/db";
import { generateSnapshot } from "./pool/snapshot";
import { referralContracts } from "./utils/contracts";
async function main() {
  // const fileName = "2023-08-18";

  // const root = await getMerkleRootFromFile(fileName);
  // console.log("Root Hash", root);
  // const proof = await getProofFromFile("0xffb8c9ec9951b1d22ae0676a8965de43412ceb7d", 100, fileName);
  // console.log("Proof", proof);

  // await updateSnapshotToS3(fileName);
  // const data = await readSnapshotFromS3(fileName);
  // console.log(data.length);

  await snapshot();
}

async function cronJob() {
  cron.schedule("0 0 * * *", async () => {
    console.log("Running a job at 00:00");
    await snapshot();
  });
}

async function snapshot() {
  const dateToday = new Date().toISOString().split("T")[0];

  let recordsData = await readSnapshotFromS3(dateToday);
  if (!recordsData) {
    console.log("Generating new snapshot");
    recordsData = await generateSnapshot(false, dateToday);
    console.log("Saving snapshot to S3");
    await updateSnapshotToS3(recordsData);
  } else {
    console.log("Snapshot already exists");
  }

  // Save Merkel root to smart contract

  // Date to timestamp
  const timestamp = Math.floor(new Date(dateToday).getTime() / 1000);

  const referralContract = referralContracts["aa"];

  const latestMerkleRoot = await (async function () {
    try {
      return await referralContract.getLatestMerkleRoot();
    } catch (err) {
      return null;
    }
  })();

  if (latestMerkleRoot !== recordsData.root) {
    console.log("Updating merkle root", recordsData.root);
    console.log("Timestamp used", timestamp);
    const tx = await referralContract.updateMerkleRoot(timestamp, recordsData.root);
    console.log("Merkle root updated", tx.hash);
  } else {
    console.log("Merkle root is up to date");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
