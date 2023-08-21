import { getProofFromFile } from "./merkle/proof";
import { getMerkleRootFromFile } from "./merkle/root";

async function main() {
  const fileName = "2023-08-18";

  const root = await getMerkleRootFromFile(fileName);
  console.log("Root Hash", root);
  const proof = await getProofFromFile("0xffb8c9ec9951b1d22ae0676a8965de43412ceb7d", 100, fileName);
  console.log("Proof", proof);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
