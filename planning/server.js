// DayXero task tracker — tiny local server. No dependencies.
// Start: npm run tracker  (or: node planning/server.js)
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT) || 4321;
const ROOT = __dirname;
const TASKS = path.join(ROOT, 'tasks.json');

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
};

const readTasks = () => JSON.parse(fs.readFileSync(TASKS, 'utf8'));
const writeTasks = (data) => {
  data.meta.updated = new Date().toISOString();
  fs.writeFileSync(TASKS, JSON.stringify(data, null, 2) + '\n');
};

function send(res, code, body, type = 'application/json; charset=utf-8') {
  res.writeHead(code, { 'Content-Type': type, 'Cache-Control': 'no-store' });
  res.end(body);
}

function handleSignoff(req, res) {
  let raw = '';
  req.on('data', (c) => (raw += c));
  req.on('end', () => {
    try {
      const { section, action, comment } = JSON.parse(raw || '{}');
      const data = readTasks();
      const s = data.sections.find((x) => x.id === section);
      if (!s) return send(res, 404, JSON.stringify({ error: 'unknown section' }));
      if (action !== 'approve' && action !== 'request_changes') {
        return send(res, 400, JSON.stringify({ error: 'bad action' }));
      }
      if (action === 'request_changes' && !String(comment || '').trim()) {
        return send(res, 400, JSON.stringify({ error: 'comment required' }));
      }
      const time = new Date().toISOString();
      const state = action === 'approve' ? 'signed_off' : 'changes_requested';
      s.signoff.state = state;
      s.signoff.history.push({ time, state, by: 'Milan', comment: comment || '' });
      data.log.unshift({
        time,
        type: 'signoff',
        message: `${s.id} mockups ${action === 'approve' ? 'approved' : 'changes requested'} by Milan${comment ? `: ${comment}` : ''}`,
      });
      writeTasks(data);
      send(res, 200, JSON.stringify({ ok: true }));
    } catch (e) {
      send(res, 500, JSON.stringify({ error: e.message }));
    }
  });
}

http
  .createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    if (req.method === 'GET' && url.pathname === '/api/tasks') {
      return send(res, 200, fs.readFileSync(TASKS));
    }
    if (req.method === 'POST' && url.pathname === '/api/signoff') return handleSignoff(req, res);
    if (req.method !== 'GET') return send(res, 405, '{}');

    const rel = url.pathname === '/' ? 'index.html' : decodeURIComponent(url.pathname.slice(1));
    const file = path.normalize(path.join(ROOT, rel));
    if (!file.startsWith(ROOT + path.sep) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
      return send(res, 404, 'Not found', 'text/plain');
    }
    send(res, 200, fs.readFileSync(file), TYPES[path.extname(file)] || 'application/octet-stream');
  })
  .on('error', (e) => {
    if (e.code === 'EADDRINUSE') console.error(`Port ${PORT} is taken. Try: PORT=4322 npm run tracker`);
    else console.error(e);
    process.exit(1);
  })
  .listen(PORT, () => console.log(`DayXero tracker → http://localhost:${PORT}`));
