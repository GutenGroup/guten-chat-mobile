#!/usr/bin/env node
// render-backlog.mjs [owner/repo] [--out BACKLOG.md] [--check]
//   Renders BACKLOG.md from the repo's open issues labelled `backlog`, ranked by cost then age.
//   The repo defaults to the git remote of the cwd, or GITHUB_REPOSITORY.
//   The rendered file is never hand-edited: --check exits 1 when the file differs from what
//   would be rendered; otherwise the file is written only when it changed (prints CHANGED /
//   UNCHANGED).
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';

const STAMP = '<!-- GENERATED from GitHub Issues (label: backlog) by render-backlog.mjs — never edit by hand; run the curator -->';

const gh = (args) => execFileSync('gh', args, { encoding: 'utf8' });

function repoFromRemote() {
  try {
    const url = execFileSync('git', ['config', '--get', 'remote.origin.url'], { encoding: 'utf8' }).trim();
    const m = url.match(/github\.com[:/]([^/]+\/[^/]+?)(?:\.git)?$/);
    if (m) return m[1];
  } catch {}
  return process.env.GITHUB_REPOSITORY ?? null;
}

let out = 'BACKLOG.md';
let check = false;
const positional = [];
const args = process.argv.slice(2);
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--out') out = args[++i];
  else if (args[i] === '--check') check = true;
  else positional.push(args[i]);
}
const repo = positional[0] ?? repoFromRemote();

if (!repo) {
  console.error('usage: node render-backlog.mjs [owner/repo] [--out BACKLOG.md] [--check]');
  process.exit(2);
}

const issues = JSON.parse(
  gh(['issue', 'list', '-R', repo, '--label', 'backlog', '--state', 'open', '--limit', '500',
      '--json', 'number,title,labels,assignees,createdAt,url'])
);

const rankOf = (names) =>
  names.includes('cost:high') ? 0 : names.includes('cost:medium') ? 1 : names.includes('cost:low') ? 2 : 3;
const groups = [[], [], [], []];
for (const iss of issues) groups[rankOf(iss.labels.map((l) => l.name))].push(iss);
for (const g of groups) g.sort((a, b) => Date.parse(a.createdAt) - Date.parse(b.createdAt));

const today = new Date().toISOString().slice(0, 10);
const lines = [STAMP, '', `# Backlog — ${repo}`, ''];
if (issues.length === 0) {
  lines.push('Nothing curated yet.', '');
} else {
  lines.push(
    `Rendered ${today} from ${issues.length} open issues labelled backlog. Add an item: open an issue, or say it to the curator. Pick an item: assign yourself.`,
    ''
  );
  const sections = [
    ['Now (cost:high)', groups[0]],
    ['Next (cost:medium)', groups[1]],
    ['Later (cost:low)', groups[2]],
    ['Unranked', groups[3]],
  ];
  for (const [name, items] of sections) {
    if (items.length === 0) continue;
    lines.push(`## ${name}`, '');
    for (const iss of items) {
      const names = iss.labels.map((l) => l.name);
      let line = `- [#${iss.number}](${iss.url}) ${iss.title}`;
      if (names.includes('agent:go')) line += ' · agent:go';
      if (iss.assignees.length > 0) line += ` · @${iss.assignees[0].login}`;
      lines.push(line);
    }
    lines.push('');
  }
}
const rendered = lines.join('\n');

const current = existsSync(out) ? readFileSync(out, 'utf8') : null;
if (check) {
  if (current !== rendered) {
    console.error(`${out} is out of date — run render-backlog.mjs`);
    process.exit(1);
  }
  console.log('UNCHANGED');
  process.exit(0);
}
if (current === rendered) {
  console.log('UNCHANGED');
  process.exit(0);
}
writeFileSync(out, rendered);
console.log('CHANGED');
