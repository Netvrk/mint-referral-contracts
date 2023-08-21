import request, { gql } from "graphql-request";
import { SUBGRAPH_ENDPOINT } from "../utils/constants";

interface UserToken {
  tokenId: number;
  active: boolean;
}

export async function getUsersFromMainnetPool(blockHeight: number = 0): Promise<string[]> {
  const users = new Set<string>();
  const block = blockHeight > 0 ? `block: { number: ${blockHeight} }` : "";
  let skip = 0;
  while (true) {
    const query = gql`
    query ($pool: String) {
      accounts(first: 1000, skip: ${skip}, ${block}) {
        address
      }
    }
  `;
    const res: any = await request(SUBGRAPH_ENDPOINT, query);
    for (let acc of res.accounts) {
      users.add(acc.address);
    }
    if (res.accounts.length < 1000) {
      break;
    }
    skip += 1000;
  }
  return [...users];
}

export async function getUserTokensFromMainnetPool(pool: string, account: string, blockHeight: number = 0): Promise<UserToken[]> {
  const block = blockHeight > 0 ? `block: { number: ${blockHeight} }` : "";

  let skip = 0;
  const tokens = new Set<UserToken>();
  while (true) {
    const query = gql`
    query ($owner: Bytes, $pool: String) {
      nfts(first: 1000, skip: ${skip}, where: { owner: $owner, pool: $pool }, ${block}) {
        tokenId
        active
      }
    }
  `;
    const params: any = { owner: account ? account : "", pool };
    const res: any = await request(SUBGRAPH_ENDPOINT, query, params);
    for (let nft of res.nfts) {
      tokens.add({
        tokenId: parseInt(nft.tokenId),
        active: nft.active,
      });
    }
    if (res.nfts.length < 1000) {
      break;
    }
    skip += 1000;
  }
  return [...tokens];
}
