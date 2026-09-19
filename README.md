# SD-WAN Device & Configuration Manager (Full-Stack)

A resilient full-stack SD-WAN orchestration platform featuring a Rails 8 API backend, Sidekiq background workers, PostgreSQL JSONB storage, and a real-time React/Tailwind frontend dashboard for automated configuration drift detection and zero-touch edge reconciliation.

## Tech Stack
- **Backend:** Ruby on Rails 8 (API-only mode)
- **Frontend:** React 18, Vite, Tailwind CSS, Lucide Icons, Axios
- **Database:** PostgreSQL (JSONB config storage, GIN indexes)
- **Queuing & Concurrency:** Redis & Sidekiq 8 (Dedicated queues, 409 Conflict concurrency lock)
- **Hardware Simulation:** Custom Ruby TCP Mock SD-WAN Gateway (`mock_gateway.rb`)

## Key Architecture & Features
1. **Idempotent Reconciliation:** Enqueues async tasks returning `202 Accepted` to prevent web thread exhaustion.
2. **Concurrency Locking:** 409 Conflict guard prevents parallel sync executions per edge device.
3. **Algorithmic Diff Engine:** Recursively evaluates Desired Template Blueprints against live router running configs to flag `missing`, `modified`, and `unexpected` keys.
4. **Interactive Dashboard:** Live telemetry KPI cards, automated short-polling during pending syncs, and a slide-over modal for JSONB drift inspection.

```markdown
## Local Development & Testing Guide

This project consists of four interconnected processes:
1. **Mock SD-WAN Gateway** (Simulates edge router hardware over HTTP on port `4567`)
2. **Sidekiq Worker** (Consumes Redis queues and computes config diffs asynchronously)
3. **Rails 8 API Backend** (Exposes REST endpoints on port `3000`)
4. **Vite + React Frontend** (Real-time edge telemetry dashboard on port `5173`)

---

### 1. System Prerequisites

Ensure the following runtimes and services are installed on your workstation:
- **Ruby:** `3.3.4+` (managed via `rbenv` or `rvm`)
- **Node.js:** `v18.20+` or `v20+`
- **PostgreSQL:** `14+` running locally
- **Redis:** `7+` running locally (required for Sidekiq async jobs)

Verify system services are running:
```bash
sudo systemctl status postgresql
sudo systemctl status redis-server

```

---

### 2. Backend Installation & Database Setup

1. **Install Ruby gems:**
```bash
bundle install

```


2. **Set up database and seed edge topologies:**
```bash
bin/rails db:create db:migrate db:seed

```


*This seeds demo organizations, sites, devices (`chi-edge-01`), and JSONB configuration blueprints.*
3. **Verify backend tests:**
```bash
bundle exec rspec

```

---

### 3. Frontend Installation

1. **Navigate to the client directory and install dependencies:**
```bash
cd client
npm install
cd ..

```


2. **Ensure client environment variables exist:**
Create `client/.env` (if not already present):
```env
VITE_API_URL=http://localhost:3000/api/v1

```

---

### 4. Running the Entire Stack Locally

Open **4 separate terminal tabs** in the project root:

| Terminal | Process | Command |
| --- | --- | --- |
| **Terminal 1** | **Mock Gateway (Hardware)** | `ruby mock_gateway.rb` |
| **Terminal 2** | **Sidekiq Worker** | `SDWAN_GATEWAY_URL="http://127.0.0.1:4567" bundle exec sidekiq -C config/sidekiq.yml -e development` |
| **Terminal 3** | **Rails 8 API Server** | `bin/rails server -p 3000` |
| **Terminal 4** | **React / Vite Dashboard** | `cd client && npm run dev` |

Once all four are booted, open `http://localhost:5173` in your browser.

---

### 5. Step-by-Step Manual Verification Scenarios

#### Scenario A: Verify Baseline Compliance (In-Sync State)

1. Navigate to `http://localhost:5173`.
2. Inspect `chi-edge-01` on the dashboard. The badge should display **In Sync** (green).
3. Click **View Drift & Diff**. The slide-over modal displays:
* Configuration State: `active`
* Algorithmic Drift Payload: `{}` (empty JSON object indicating zero configuration divergence).



#### Scenario B: Simulate Configuration Drift & Automated Reconciliation

1. Open `mock_gateway.rb` in your editor.
2. Under the `GET /api/v1/devices/EDGE-2432-AB/config` route, modify one of the interface IPs to simulate an out-of-band change made directly on the router:
```ruby
{ "name" => "eth1", "enabled" => true, "ip_address" => "10.0.0.99/30" }

```


3. Restart Terminal 1 (`Ctrl + C`, then `ruby mock_gateway.rb`).
4. On the web dashboard, click **Sync** on `chi-edge-01`.
5. Observe the execution flow:
* The button flips to a spinner (`Pending`) and the status turns amber (`Sync Pending`).
* Terminal 2 (Sidekiq) logs `start SyncDeviceConfigWorker`, queries the gateway, and calculates the delta using `ConfigDiffService`.
* Within 2.5 seconds, the UI auto-polls and updates the badge to **Drift Detected** (red).


6. Click **View Drift & Diff** to inspect the detected drift:
* `diff_payload.modified.interfaces` highlights `10.0.0.1/30` (desired) vs. `10.0.0.99/30` (running).



#### Scenario C: Verify Concurrency Lock (HTTP 409 Conflict)

1. Trigger a synchronization job by clicking **Sync**.
2. Immediately click the sync trigger again before the first cycle completes.
3. Observe the client toast notification:
> *"Conflict: A sync job is already pending for this router."*


4. Confirm Rails rejected the race condition with an `HTTP 409 Conflict` response to protect database state integrity.

```