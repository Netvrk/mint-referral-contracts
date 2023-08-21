export async function saveToFile(csvFile: any, snapshotData: any) {
  snapshotData = snapshotData.map((x: any) => {
    return {
      user: x.user,
      factor: parseInt(x.factor * 100 + ""),
      total: x.total,
      staked: x.staked,
      unstaked: x.unstaked,
    };
  });

  await csvFile.add(snapshotData);
}
