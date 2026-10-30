// Use the bundled @oai/artifact-tool. Source/template is the existing 13-slide deck.
import fs from 'node:fs/promises';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const root = process.cwd();
const modules = process.env.RUNTIME_NODE_MODULES;
if (!modules) throw new Error('Set RUNTIME_NODE_MODULES to load_workspace_dependencies Node packages');
const {PresentationFile, FileBlob} = await import(pathToFileURL(path.join(modules,'@oai/artifact-tool/dist/artifact_tool.mjs')).href);
const source = path.join(root,'output/presentations/BeeWise-Lab3-Review-DRAFT.pptx');
const privateDir = path.join(root,'tmp/deck-corrective');
await fs.mkdir(privateDir,{recursive:true});
const original = await fs.readFile(source);
await fs.writeFile(path.join(privateDir,'source.pptx'),original);
const p = await PresentationFile.importPptx(new FileBlob(original));
const data = JSON.parse(await fs.readFile('output/source/corrective-artifacts.json','utf8'));
const inspection = await p.inspect({kind:'textbox', maxChars:100000});
for (const record of inspection.records) {
  const update = data.slideUpdates[String(record.slideIndex+1)];
  if (!update) continue;
  const y = record.position?.top;
  const key = record.slideIndex === 0 ?
    (record.text.startsWith('Cloud-enabled') ? 'subtitle' : record.text.startsWith('- Flutter') ? 'body' : null) :
    y > 650 && record.position.width > 500 ? 'footer' :
    y >= 170 && y < 260 ? 'subtitle' : y >= 260 && y < 640 ? 'body' : null;
  if (!key || !update[key]) continue;
  // Keep the source geometry, font, color and typography.
  const shape = p.resolve(record.id);
  shape.text = update[key];
  shape.text.style = record.style;
}
for (const [i, slide] of p.slides.items.entries()) {
  const png = await p.export({slide,format:'png',scale:1});
  await fs.writeFile(path.join(privateDir,`slide-${String(i+1).padStart(2,'0')}.png`), new Uint8Array(await png.arrayBuffer()));
}
const pptx = await PresentationFile.exportPptx(p);
const candidatePath = path.join(privateDir,'candidate.pptx');
await fs.writeFile(candidatePath,pptx.data);
console.log(JSON.stringify({candidatePath,slides:p.slides.items.length,sourceSha:data.testedCode}));
