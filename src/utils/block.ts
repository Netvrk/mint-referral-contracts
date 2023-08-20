import axios from "axios";

export default async function getClosestBlock(timestamp: number, network: string) {
  try {
    const res: any = await axios.get(`https://coins.llama.fi/block/${network}/${timestamp}`);
    return res.data.height;
  } catch (e) {
    console.log(e);
    return null;
  }
}
