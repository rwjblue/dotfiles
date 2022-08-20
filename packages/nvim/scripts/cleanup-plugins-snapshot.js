import { promises as fs } from 'node:fs';

async function main(snapshotPath) {
  console.log(`sorting and cleaning up ${snapshotPath}`);

  const contents = await fs.readFile(snapshotPath);
  const snapshot = JSON.parse(contents);

  const sorted = {};
  for (let key of Object.keys(snapshot).sort()) {
    sorted[key] = snapshot[key];
  }

  await fs.writeFile(snapshotPath, JSON.stringify(sorted, null, 2));

  console.log(`snapshot written!`);
}

main(process.argv[2]);
