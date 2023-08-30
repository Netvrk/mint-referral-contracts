import { getMerkleRootFromFile } from "./merkle/root";
import { updateSnapshotToS3 } from "./pool/db";
import { generateSnapshot } from "./pool/snapshot";

async function main() {
  // const fileName = "2023-08-18";

  // const root = await getMerkleRootFromFile(fileName);
  // console.log("Root Hash", root);
  // const proof = await getProofFromFile("0xffb8c9ec9951b1d22ae0676a8965de43412ceb7d", 100, fileName);
  // console.log("Proof", proof);

  // await updateSnapshotToS3(fileName);
  // const data = await readSnapshotFromS3(fileName);
  // console.log(data.length);

  await snapshotCron();
}

async function snapshotCron() {
  const filename = new Date().toISOString().split("T")[0];
  await generateSnapshot(false, filename);
  const root = await getMerkleRootFromFile(filename);
  console.log("Root Hash", root);
  await updateSnapshotToS3(filename);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
