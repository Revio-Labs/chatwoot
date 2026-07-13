# Load testing the workflow engine

These [k6](https://k6.io) scripts stress the native workflow engine through the
**real widget API**, so you can see how it holds up at Drive lah scale
(~190K conversations/year, with real peaks) **before** cutting over from Intercom.

> Why this matters: the bottleneck under load is not raw HTTP — it's the
> background pipeline (`EventDispatcherJob` → `Workflows::AdvanceJob` →
> `RunnerService`) draining fast enough. A single test user already exhausted a
> 512 MB worker's DB pool. Load-test **against staging**, never production.

## Prerequisites

1. Install k6: `brew install k6` (or see https://k6.io/docs/get-started/installation/).
2. A **staging** Chatwoot with the workflow engine deployed and the AU Hosts
   workflow set **Live**.
3. The widget inbox's **website token** — Settings → Inboxes → *(your widget)* →
   Configuration → the `websiteToken` in the embed snippet.
4. For a clean run, **turn off the pre-chat form** on that inbox so conversations
   start straight into the workflow (Settings → Inboxes → Pre Chat Form → off).

## Run

```bash
k6 run \
  -e CHATWOOT_URL=https://<your-staging>.onrender.com \
  -e WEBSITE_TOKEN=<website token> \
  -e BUTTON_VALUE=trip_issue \
  test/load/workflow_widget_load.js
```

Override the load shape:

```bash
# 200 concurrent hosts, sustained for 5 minutes
k6 run -e VUS=200 -e DURATION=5m -e CHATWOOT_URL=... -e WEBSITE_TOKEN=... \
  test/load/workflow_widget_load.js
```

Each virtual user boots a fresh widget session (auto-minting its own auth token
via `POST /widget/config`), opens a conversation, polls for the bot's welcome
menu, and taps a button.

## Pass/fail thresholds (in the script)

| Metric | Target |
|---|---|
| `http_req_failed` | < 1% |
| `http_req_duration` p95 | < 3s (widget API) |
| `bot_response_time` p95 | < 5s (open → bot's buttons) |
| `bot_replied` | > 98% of conversations get a bot reply |

`bot_response_time` is the number that matters most — it's the real
end-to-end latency a host experiences waiting for the menu, and it degrades
first when the worker/DB is undersized.

## Watch the backend while it runs (the other half)

k6 only sees HTTP. The workflow runs async, so also watch:

- **Sidekiq queue depth** (`high` + `critical` queues). If they climb and don't
  drain, the worker is too small or `SIDEKIQ_CONCURRENCY` is too high for the DB
  pool. Chatwoot exposes Sidekiq at `/monitoring/sidekiq` (super admin), or use
  `Sidekiq::Queue.new('high').size` in the console.
- **Postgres connections** — `SELECT count(*) FROM pg_stat_activity;`. If you see
  `could not obtain a connection from the pool`, raise `RAILS_MAX_THREADS` (DB
  pool) to ≥ `SIDEKIQ_CONCURRENCY`, and/or the DB's `max_connections`.
- **Worker memory** on Render. Sidekiq + the app commonly needs 1–2 GB; 512 MB
  OOM-loops under load.

## Interpreting results / right-sizing

- Start small (`-e VUS=50`) to confirm the flow works, then ramp.
- If `bot_response_time` p95 blows past 5s or `bot_replied` drops, the async
  pipeline is the constraint — scale the **worker** (instance size + concurrency)
  and the **DB pool** together before scaling the web tier.
- Re-run after each change; the thresholds turn "is it Intercom-ready?" into a
  pass/fail signal.
