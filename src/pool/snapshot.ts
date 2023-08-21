import * as fs from "fs";
import * as path from "path";
import getClosestBlock from "../utils/block";
import { CsvFile } from "../utils/csv-file";
import { saveToFile } from "./saveToFile";
import { getUserTokensFromMainnetPool, getUsersFromMainnetPool } from "./users";

const mainnetPools = ["land", "transport", "avatar", "bonus"];

interface UserToken {
  [user: string]: {
    [pool: string]: {
      staked: number;
      unstaked: number;
      total: number;
      tokenIds: number[];
    };
  };
}

export async function generateSnapshot(recent: boolean = true, date: string = "") {
  if (recent) {
    date = new Date().toISOString().split("T")[0];
  }

  let out = path.join(__dirname, `../../exports/snapshots/`);
  if (!fs.existsSync(out)) {
    fs.mkdirSync(out, { recursive: true });
  }

  out = path.join(out, `/${date}.csv`);

  const csvFile = new CsvFile({
    path: out,
    headers: ["user", "staked", "unstaked", "total", "factor"],
  });

  // date to timestamp
  const timestamp = new Date(date).getTime() / 1000;

  const blockHeight = await getClosestBlock(timestamp, "ethereum");

  const users = await getUsersFromMainnetPool(blockHeight);

  console.log("Users", users.length);
  const batchSize = 50;
  for (let x = 0; x < users.length; x += batchSize) {
    const result: UserToken = {};

    const batchUsers = users.slice(x, x + batchSize);

    const res = await Promise.all(
      batchUsers.map(async (user) => {
        const userData: any = {};
        for (let pool of mainnetPools) {
          const tokens = await getUserTokensFromMainnetPool(pool, user, blockHeight);
          const staked = tokens.filter((t) => t.active);
          const unstaked = tokens.filter((t) => !t.active);

          userData[pool] = {
            staked: staked.length,
            unstaked: unstaked.length,
            total: tokens.length,
            tokenIds: tokens.map((t) => t.tokenId),
          };
        }
        console.log(`User: ${user} done`);
        return userData;
      })
    );

    for (let i = 0; i < batchUsers.length; i++) {
      result[batchUsers[i]] = res[i];
    }

    // sleep for 10 sec
    console.log(`${x + batchUsers.length}/${users.length} items done`);
    await new Promise((resolve) => setTimeout(resolve, 10000));

    const snapshotData = [];

    for (let user of Object.keys(result)) {
      let total = 0;
      let staked = 0;

      for (let pool of Object.keys(result[user])) {
        total += result[user][pool].total;
        staked += result[user][pool].staked;
      }

      snapshotData.push({
        user,
        factor: staked / total || 0,
        staked: staked,
        unstaked: total - staked,
        total: total,
      });
    }

    await saveToFile(csvFile, snapshotData);
  }

  console.log("Snapshot generated and saved to file");
}
