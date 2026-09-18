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

## Quickstart & Local Setup

### 1. Backend Setup
```bash
# Install dependencies
bundle install

# Database setup & seeding demo edge routers
bin/rails db:create db:migrate db:seed


# Run the test suite
bundle exec rspec

# Start server & background worker
rails server
bundle exec sidekiq