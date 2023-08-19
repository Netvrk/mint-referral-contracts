import { getUserTokensFromMainnetPool, getUsersFromMainnetPool } from "./pool/users";

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

async function main() {
  const users = await getUsersFromMainnetPool();
  let result: UserToken = {};
  for (let user of users) {
    console.log(`User: ${user}`);
    for (let pool of mainnetPools) {
      const tokens = await getUserTokensFromMainnetPool(pool, user);
      const staked = tokens.filter((t) => t.active);
      const unstaked = tokens.filter((t) => !t.active);
      if (!result[user]) {
        result[user] = {};
      }
      result[user][pool] = {
        tokenIds: tokens.map((t) => t.tokenId),
        total: tokens.length,
        staked: staked.length,
        unstaked: unstaked.length,
      };
    }
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
