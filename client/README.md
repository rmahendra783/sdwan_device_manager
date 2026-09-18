A fast, responsive Vite + React dashboard with Tailwind CSS designed for real-time edge router inventory monitoring, automated drift detection, and configuration reconciliation.

## Features
- **Live Inventory Grid:** Visual indicators for `in_sync`, `sync_pending`, and `out_of_sync` router states.
- **Config Drift Inspector:** Side-by-side modal displaying database blueprints vs. live algorithmic diff payloads (`diff_payload`).
- **Real-Time Polling Loop:** Auto-updates UI state every 2.5 seconds while background workers are actively reconciling edge hardware.
- **Concurrency Toast Notifications:** Handles `409 Conflict` gracefully when duplicate jobs are triggered.

## Local Development
```bash
npm install
npm run dev