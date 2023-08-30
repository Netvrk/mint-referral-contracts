import axios from "axios";
import * as fs from "fs";
import * as path from "path";
import { CsvFile } from "../utils/csv-file";

import * as dotenv from "dotenv";
dotenv.config();

export async function updateSnapshotToS3(filename: string = "") {
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
  const res = await axios.post(
    process.env.S3_API_URL + "/snapshot",
    {
      name: filename,
      data: records,
    },
    {
      headers: {
        "Content-Type": "application/json",
        "x-api-key": process.env.S3_API_KEY,
      },
    }
  );

  const { message } = res.data;
  console.log(message);
  return message;
}

export async function readSnapshotFromS3(filename: string = "") {
  const res = await axios.get(process.env.S3_API_URL + "/snapshot/" + filename, {
    headers: {
      "x-api-key": process.env.S3_API_KEY,
    },
  });
  const { data } = res.data;
  return data;
}
