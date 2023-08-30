import { getProof } from "../merkle/proof";
import { getMerkleRoot, getMerkleTree } from "../merkle/root";
import getClosestBlock from "../utils/block";
import { getUserTokensFromMainnetPool, getUsersFromMainnetPool } from "./users";

const mainnetPools = ["land", "transport", "avatar", "bonus"];

interface UserToken {
  [user: string]: {
    [pool: string]: {
      staked: number;
      unstaked: number;
      total: number;
      tokenIds: number[];
      proof?: string[][] | null;
    };
  };
}

export async function generateSnapshot(recent: boolean = true, filename: string = "") {
  if (recent) {
    filename = new Date().toISOString().split("T")[0];
  }

  // date to timestamp
  const timestamp = new Date(filename).getTime() / 1000;

  const blockHeight = await getClosestBlock(timestamp, "ethereum");

  const users = await getUsersFromMainnetPool(blockHeight);

  console.log("Users", users.length);
  const batchSize = 50;

  const snapshotData: any = [];

  for (let x = 0; x < users.length; x += batchSize) {
    const userRecords: UserToken = {};

    const batchUsers = users.slice(x, x + batchSize);

    const usersData = await Promise.all(
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
      userRecords[batchUsers[i]] = usersData[i];
    }

    // sleep for 10 sec
    console.log(`${x + batchUsers.length}/${users.length} items done`);
    await new Promise((resolve) => setTimeout(resolve, 10000));

    // Push to snapshotData
    for (let user of Object.keys(userRecords)) {
      let total = 0;
      let staked = 0;

      for (let pool of Object.keys(userRecords[user])) {
        total += userRecords[user][pool].total;
        staked += userRecords[user][pool].staked;
      }

      snapshotData.push({
        user,
        factor: parseInt((staked / total || 0) * 100 + ""),
        staked: staked,
        unstaked: total - staked,
        total: total,
      });
    }
  }

  // Update Proof for all users
  const tree = getMerkleTree(snapshotData);
  const snapshotDataWithProof = await Promise.all(
    snapshotData.map(async (user: any) => {
      user.proof = await getProof(tree, user.user, user.factor);
      return user;
    })
  );

  // Update Root and metadata
  const root = (await getMerkleRoot(snapshotData)) || "";
  return {
    snapshot: filename,
    root,
    records: snapshotDataWithProof,
  };
}
