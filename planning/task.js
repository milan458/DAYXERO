#!/usr/bin/env node
// CLI for keeping planning/tasks.json current. Every change is logged.
//
//   node planning/task.js status S1.1 in_progress ["note"]
//   node planning/task.js add S1 "Title" "where it came from"   [--blocked]
//   node planning/task.js note S1.1 "text"
//   node planning/task.js signoff S1 mockups_ready
//   node planning/task.js mockup S1 "Title" mockups/S1/file.html
//   node planning/task.js now S1 S1.4 ["waiting item" ...]
const fs = require('fs');
const path = require('path');

const TASKS = path.join(__dirname, 'tasks.json');
const STATUSES = ['pending', 'in_progress', 'blocked', 'awaiting_signoff', 'done'];
const SIGNOFF = ['not_started', 'mockups_ready', 'changes_requested', 'signed_off'];

const data = JSON.parse(fs.readFileSync(TASKS, 'utf8'));
const now = new Date().toISOString();
const [cmd, ...args] = process.argv.slice(2);

const die = (msg) => {
  console.error(msg);
  process.exit(1);
};
const section = (id) => data.sections.find((s) => s.id === id) || die(`No section ${id}`);
const task = (id) => {
  for (const s of data.sections) {
    const t = s.tasks.find((x) => x.id === id);
    if (t) return t;
  }
  die(`No task ${id}`);
};
const log = (type, message) => data.log.unshift({ time: now, type, message });

switch (cmd) {
  case 'status': {
    const [id, status, note] = args;
    if (!STATUSES.includes(status)) die(`Status must be one of: ${STATUSES.join(', ')}`);
    const t = task(id);
    const from = t.status;
    t.status = status;
    t.completed = status === 'done' ? now : null;
    if (note) t.notes = t.notes ? `${t.notes}\n${note}` : note;
    log('status', `${id} ${from} → ${status}${note ? ` (${note})` : ''}`);
    break;
  }
  case 'add': {
    const blocked = args.includes('--blocked');
    const [sid, title, note] = args.filter((a) => a !== '--blocked');
    const s = section(sid);
    const n = Math.max(0, ...s.tasks.map((t) => Number(t.id.split('.')[1]) || 0)) + 1;
    const id = `${sid}.${n}`;
    s.tasks.push({ id, title, status: blocked ? 'blocked' : 'pending', notes: note || '', created: now, completed: null });
    log('task_added', `${id} added: ${title}`);
    console.log(id);
    break;
  }
  case 'note': {
    const [id, text] = args;
    const t = task(id);
    t.notes = t.notes ? `${t.notes}\n${text}` : text;
    log('note', `${id}: ${text}`);
    break;
  }
  case 'signoff': {
    const [sid, state] = args;
    if (!SIGNOFF.includes(state)) die(`State must be one of: ${SIGNOFF.join(', ')}`);
    const s = section(sid);
    s.signoff.state = state;
    s.signoff.history.push({ time: now, state, by: 'Claude', comment: '' });
    log('signoff', `${sid} mockups → ${state}`);
    break;
  }
  case 'mockup': {
    const [sid, title, file] = args;
    section(sid).mockups.push({ title, path: file });
    log('mockup', `${sid} mockup posted: ${title}`);
    break;
  }
  case 'now': {
    const [sid, tid, ...waiting] = args;
    data.now = { section: sid, task: tid, waiting_on_milan: waiting };
    log('now', `Now: ${sid} / ${tid}`);
    break;
  }
  default:
    die('Commands: status | add | note | signoff | mockup | now');
}

data.meta.updated = now;
fs.writeFileSync(TASKS, JSON.stringify(data, null, 2) + '\n');
