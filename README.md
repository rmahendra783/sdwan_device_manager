# SD-WAN Device & Configuration Manager (API-Only)

A resilient Ruby on Rails backend service designed for Cisco SD-WAN device orchestration, automated configuration drift detection (Diff Engine), and idempotent mass-deployment via asynchronous workers.

## Tech Stack
- **Ruby on Rails** (API-only mode)
- **PostgreSQL** (JSONB config storage, GIN indexes, multi-tenant relational schema)
- **Redis & Sidekiq** (Asynchronous deployment pipelines with rate limiting and idempotency)
- **Faraday** (Resilient external API client with timeouts and retries)
- **RSpec & WebMock** (TDD for config diff computation and API error states)

## Architecture Overview
1. **REST Interface:** Accepts configuration intents and returns `202 Accepted`.
2. **Orchestrator:** Slices bulk rollouts into isolated, concurrent device tasks.
3. **Diff Engine (`ConfigDiffService`):** Recursively compares desired JSON/YANG definitions against live running configurations to detect configuration drift.
4. **Mock SD-WAN Client:** Simulates Cisco SD-WAN Manager API responses, handling network timeouts, 401 token refreshes, and backoff retries.

## Setup & Running Locally
```bash
# Install dependencies
bundle install

# Database setup & seeding demo SD-WAN topologies
rails db:create db:migrate db:seed

# Run the test suite
bundle exec rspec

# Start server & background worker
rails server
bundle exec sidekiq