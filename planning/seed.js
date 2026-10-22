#!/usr/bin/env node
// One-off: builds planning/tasks.json from docs/DAYXERO_V1_HANDOFF.md part 2.
// Refuses to overwrite an existing tasks.json (use --force to rebuild from scratch).
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, 'tasks.json');
const PLAN = path.join(__dirname, '..', 'docs', 'DAYXERO_V1_HANDOFF.md');
if (fs.existsSync(OUT) && !process.argv.includes('--force')) {
  console.error('tasks.json exists; pass --force to rebuild it.');
  process.exit(1);
}

const now = new Date().toISOString();
const lines = fs.readFileSync(PLAN, 'utf8').split('\n');
const sections = [];
let inPart2 = false;
let current = null;

for (const line of lines) {
  if (line.startsWith('## 2.')) inPart2 = true;
  else if (line.startsWith('## 3.')) break;
  if (!inPart2) continue;

  const head = line.match(/^### Section (\d+) · (.+)$/);
  if (head) {
    current = {
      id: `S${head[1]}`,
      title: head[2].trim(),
      goal: '',
      signoff: { state: 'not_started', history: [] },
      mockups: [],
      tasks: [],
    };
    sections.push(current);
    continue;
  }
  if (!current) continue;
  const goal = line.match(/^Goal: (.+)$/);
  if (goal) current.goal = goal[1].trim();
  const t = line.match(/^- (S\d+\.\d+) (.+)$/);
  if (t) current.tasks.push({ id: t[1], title: t[2].trim(), status: 'pending', notes: '', created: now, completed: null });
}

const total = sections.reduce((n, s) => n + s.tasks.length, 0);
const data = {
  meta: { project: 'DayXero v1', source: 'docs/DAYXERO_V1_HANDOFF.md', updated: now },
  now: { section: 'S1', task: null, waiting_on_milan: [] },
  sections,
  log: [{ time: now, type: 'task_added', message: `Loaded ${total} tasks across ${sections.length} sections from the handoff plan` }],
};
fs.writeFileSync(OUT, JSON.stringify(data, null, 2) + '\n');
console.log(`Wrote ${total} tasks in ${sections.length} sections.`);
