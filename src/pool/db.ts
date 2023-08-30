import axios from "axios";

import * as dotenv from "dotenv";
dotenv.config();

export async function updateSnapshotToS3(recordsData: any) {
  const res = await axios.post(
    process.env.S3_API_URL + "/snapshot",
    {
      name: recordsData.snapshot,
      data: recordsData,
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
  try {
    const res = await axios.get(process.env.S3_API_URL + "/snapshot/" + filename, {
      headers: {
        "x-api-key": process.env.S3_API_KEY,
      },
    });
    const { data } = res.data;

    return data;
  } catch (err) {
    console.log(err);
    return null;
  }
}
