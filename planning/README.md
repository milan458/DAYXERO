# Planning

Start the tracker: `npm run tracker` → http://localhost:4321 (if the port is taken: `PORT=4322 npm run tracker`).

- `tasks.json` is the single source of truth. The page reads it every 4 seconds; the **Approve mockups** / **Request changes** buttons write to it.
- `task.js` is how Claude updates it (status, new tasks, notes, sign-off state, mockups, the "Now" panel). Every change lands in the change log. Run `node planning/task.js` for usage.
- `mockups/<section>/` holds the mockups shown on each section.
- `seed.js` built the first `tasks.json` from `docs/DAYXERO_V1_HANDOFF.md`; it won't overwrite an existing file.
