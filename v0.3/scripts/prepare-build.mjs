import { cp, mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises';

const parts = await readdir('parts');
const gameParts = parts.filter(x => x.startsWith('game-')).sort();
const styleParts = parts.filter(x => x.startsWith('style-')).sort();

const joinParts = async (names, out) => {
  const buffers = [];
  for (const name of names) buffers.push(await readFile(`parts/${name}`));
  await writeFile(out, Buffer.concat(buffers));
};

await joinParts(gameParts, 'game.js');
await joinParts(styleParts, 'style.css');
await rm('dist', { recursive: true, force: true });
await mkdir('dist', { recursive: true });
for (const path of ['index.html', 'style.css', 'game.js', 'assets']) {
  await cp(path, `dist/${path}`, { recursive: true });
}
