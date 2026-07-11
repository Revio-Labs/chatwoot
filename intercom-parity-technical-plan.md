# Intercom Parity — Technical Implementation Plan for Chatwoot

> **Scope.** The build-ready engineering plan implementing every 🔴 GAP and 🟡 PARTIAL from `intercom-feature-reference.md` **inside Chatwoot** — same stack (Rails 7.1, Vue 3, Postgres, Redis, Sidekiq, Tailwind), minimal surgical changes, no new services. Companions: `intercom-feature-reference.md` (what & why), `intercom-feature-impl-status.md` (status tracker), `REV-49` (product PRD).
>
> **Grounding.** Every convention cited below was verified against this repo (July 2026): migration style from `db/migrate/2026*`, sequence triggers from `conversation.rb:382` / `campaign.rb:142`, event pipeline from `app/dispatchers/*` + `lib/events/types.rb`, bot ownership from `conversation.rb:286` / `inbox.rb:173`, widget reply loop from `widget/components/AgentMessageBubble.vue`, locking from `app/jobs/mutex_application_job.rb`, FE patterns from `components-next/Campaigns/*`.

---

## Table of Contents

1. [Guiding Principles](#1-guiding-principles)
2. [What We Reuse (No Changes)](#2-what-we-reuse-no-changes)
3. [Feature Flags & OSS/EE Placement](#3-feature-flags--ossee-placement)
4. [Workstream A — Workflow Engine](#4-workstream-a--workflow-engine) *(the big one)*
5. [Workstream B — Tickets](#5-workstream-b--tickets)
6. [Workstream C — Email Campaigns + Goal Tracking](#6-workstream-c--email-campaigns--goal-tracking)
7. [Workstream D — Surveys](#7-workstream-d--surveys)
8. [Workstream E — Events Tracking](#8-workstream-e--events-tracking)
9. [Workstream F — Captain Extensions](#9-workstream-f--captain-extensions)
10. [Workstream G — SSO Hardening](#10-workstream-g--sso-hardening)
11. [Workstream H — Reporting (Metabase)](#11-workstream-h--reporting-metabase)
12. [Small Extensions](#12-small-extensions)
13. [Migration Inventory & Ordering](#13-migration-inventory--ordering)
14. [Intercom → Chatwoot Data Migration](#14-intercom--chatwoot-data-migration)
15. [Testing Strategy](#15-testing-strategy)
16. [Phased Delivery Plan](#16-phased-delivery-plan)
17. [Risk Register](#17-risk-register)

---

## 1. Guiding Principles

1. **Additive only.** No existing table gets a destructive change. No existing subsystem (automation_rules, campaigns, agent_bots) is rewritten — new capabilities are new models + new listeners that plug into the existing dispatcher.
2. **Follow the house pattern, always.**
   - Migrations: `ActiveRecord::Migration[7.1]`, `t.references :account, null: false`, `t.timestamps`, jsonb defaults `{}` (objects) / `[]` (arrays), `disable_ddl_transaction!` + `algorithm: :concurrently` only for indexes on hot tables.
   - Per-account sequential IDs: **hairtrigger** DB triggers (`trigger.before(:insert)` in the model), mirroring `conv_dpid_seq_`/`camp_dpid_seq_` (`conversation.rb:382`, `campaign.rb:142`).
   - Events: dispatch via `Rails.configuration.dispatcher.dispatch(CONST, Time.zone.now, data)`; consume via a `BaseListener` subclass registered in `AsyncDispatcher` (or `SyncDispatcher` only if realtime-critical).
   - Messages: created exclusively through `Messages::MessageBuilder.new(sender, conversation, params).perform`.
   - EE code: `enterprise/app/...` + `prepend_mod_with` / `include_mod_with` from the OSS class bottom — never edit OSS files for EE-only behavior.
   - FE: `<script setup>` composition API, Tailwind tokens (`bg-n-*`, `text-n-*`), components-next UI kit, Vuex module + `useMapGetter`, route `meta: { featureFlag, permissions }`, i18n file-per-feature in `dashboard/i18n/locale/en/`.
3. **Feature-flag everything.** Each workstream ships behind a new `features.yml` entry (append-only — bit positions are load-bearing, `featurable.rb`).
4. **Runtime before builder.** Every feature is API/JSON-drivable before it gets an authoring UI; UIs never block backend go-live.
5. **Ship the happy path** per CLAUDE.md — guards only where the grounding evidence showed production needs them (locking, dedup, idempotency).

---

## 2. What We Reuse (No Changes)

| Capability | Existing code | Used by workstream |
|---|---|---|
| Message creation | `Messages::MessageBuilder` | A, C, D |
| Interactive widget messages + reply loop | `content_type: input_select/cards/form/article`; widget PATCHes `message.submitted_values` (`widget/api/message.js`) | A, B, D |
| Bot conversation ownership | `status: :pending` + `Inbox#active_bot?` (`conversation.rb:286`, `inbox.rb:173`) | A |
| Bot → human handoff + reporting | `Conversation#bot_handoff!` → `CONVERSATION_BOT_HANDOFF` → `ReportingEventListener` → `BotMetricsBuilder` | A |
| Distributed locking | `MutexApplicationJob#with_lock` + `Redis::LockManager` | A, C |
| Long-timer sweeps | sidekiq-cron pattern (`ReopenSnoozedConversationsJob` + `config/schedule.yml`) | A |
| Campaign spine | `campaign` (ongoing/one_off, audience/trigger_rules JSONB, `mark_processing!` `with_lock`, display_id trigger) | C |
| Campaign job entry | `Campaigns::TriggerOneoffCampaignJob` → per-channel service dispatch | C |
| Liquid personalization | `Liquid::CampaignTemplateService` | C |
| CSAT machinery | `input_csat`, `csat_survey_response`, `CsatSurveyListener` | D |
| Captain RAG + tools | `captain/assistant`, `captain/document`, `captain/tools/*`, `captain/scenario` | F |
| SAML + helpers | `account_saml_settings`, `SamlAuthenticationHelper` | G |
| Reporting event store | `reporting_event`, `reporting_events_rollup` | H |
| Import scaffolding | `data_import` model | §14 |

---

## 3. Feature Flags & OSS/EE Placement

**`config/features.yml` — append these (never reorder existing):**

```yaml
- name: workflows
  display_name: Workflows
  enabled: false
- name: tickets
  display_name: Tickets
  enabled: false
- name: email_campaigns
  display_name: Email Campaigns
  enabled: false
- name: surveys
  display_name: Surveys
  enabled: false
- name: events_tracking
  display_name: Events Tracking
  enabled: false
- name: campaign_goals
  display_name: Campaign Goal Tracking
  enabled: false
```

**Placement decisions:**

| Workstream | Placement | Rationale |
|---|---|---|
| A Workflow engine | **OSS** (`app/`) | Core product value for all Revio clients; mirrors automation_rules placement |
| B Tickets | **OSS** | Core helpdesk primitive |
| C Email campaigns + goals | **OSS** | Sibling of existing SMS/WhatsApp campaign services |
| D Surveys | **OSS** | Sibling of CSAT |
| E Events | **OSS** | Data-platform primitive |
| F Captain extensions | **EE** (`enterprise/`) | Captain is EE |
| G enforce_sso, SCIM | **EE** | SAML is EE (`saml` premium flag) |
| H Metabase | External | Zero Chatwoot code |

---

## 4. Workstream A — Workflow Engine

Intercom-Workflows parity: stateful, multi-step, visual bot flows. Design incorporates all 10 corrections from the codebase design review (locking, snapshotting, wake-sweeps, submitted_values, sender identity, reporting columns).

### A.1 Data model

**Migration 1 — `create_workflow_definitions`:**

```ruby
class CreateWorkflowDefinitions < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_definitions do |t|
      t.references :account, null: false, index: true
      t.references :inbox, null: false, index: true
      t.string  :name, null: false
      t.integer :status, default: 0, null: false          # draft: 0, live: 1, archived: 2
      t.integer :trigger_type, default: 0, null: false    # conversation_created: 0, first_message: 1,
                                                          # inactivity: 2, manual: 3 (reusable/invoked)
      t.integer :priority, default: 0, null: false        # list order; lower = higher priority
      t.integer :audience_type, default: 0, null: false   # customer_facing: 0, background: 1
      t.jsonb   :flow, default: {}, null: false           # { nodes: [], edges: [], variables: [] }
      t.jsonb   :trigger_rules, default: {}               # conditions (attribute filters), inactivity minutes
      t.timestamps
    end
    add_index :workflow_definitions, [:account_id, :inbox_id, :status, :priority],
              name: 'idx_workflow_defs_on_inbox_status_priority'
  end
end
```

**Migration 2 — `create_workflow_executions`:**

```ruby
class CreateWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_executions do |t|
      t.references :account, null: false, index: true
      t.references :conversation, null: false
      t.references :workflow_definition, index: true      # FK with on_delete: :nullify — see model
      t.string   :current_node_id
      t.integer  :status, default: 0, null: false         # active: 0, completed: 1, interrupted: 2, handed_off: 3
      t.jsonb    :flow_snapshot, default: {}, null: false # copied from definition at trigger time (correction #4)
      t.jsonb    :variables, default: {}                  # collected attrs; flat k/v
      t.jsonb    :steps, default: []                      # append-only [{node_id, entered_at}] (correction #9)
      t.datetime :wake_at                                 # for delay nodes (correction #5)
      t.datetime :completed_at
      t.datetime :last_activity_at
      t.timestamps
    end
    # DB backstop for "one active execution per conversation" (correction #1)
    add_index :workflow_executions, :conversation_id, unique: true,
              where: 'status = 0', name: 'idx_workflow_exec_one_active_per_conversation'
    add_index :workflow_executions, [:account_id, :workflow_definition_id, :status, :created_at],
              name: 'idx_workflow_exec_reporting'
    add_index :workflow_executions, :wake_at, where: 'status = 0 AND wake_at IS NOT NULL'
  end
end
```

**Migration 3 — additive enum value (no schema change): `AgentBot.bot_type`** already `enum bot_type: { webhook: 0 }` → add `workflow: 1` in the model (correction #8). A hidden per-account AgentBot (`bot_type: :workflow`, `outgoing_url: nil`) is created lazily and used as the message sender + `assignee_agent_bot`, reusing bot display and `reset_agent_bot_when_assignee_present` takeover semantics. `AgentBotListener#process_webhook_bot_event` already no-ops on blank `outgoing_url` — zero webhook side effects.

**Model validations (not the stock JSONB validator — correction #6):**

```ruby
# app/models/workflow_definition.rb
validates :flow, workflow_flow_size: true   # custom: nodes.length <= 100, to_json.bytesize <= 200.kilobytes
# workflow_executions.variables uses the stock validator (flat hash):
validates :variables, jsonb_attributes_length: true
```

Rollback: both tables drop cleanly (`db:rollback`); no existing table is touched.

### A.2 Node vocabulary (flow JSONB)

```jsonc
{
  "nodes": [
    { "id": "n1", "type": "send_message",  "content": "Hi {{contact.name}}!" },
    { "id": "n2", "type": "send_buttons",  "content": "How can we help?",
      "items": [ { "title": "Damage", "value": "damage" }, { "title": "Fines", "value": "fines" } ] },
    { "id": "n3", "type": "set_attribute", "scope": "contact", "key": "market", "value": "Australia" },
    { "id": "n4", "type": "branch" },
    { "id": "n5", "type": "send_image",    "url": "..." },
    { "id": "n6", "type": "send_form",     "items": [/* form field defs */] },
    { "id": "n7", "type": "collect_input", "save_to": "damage_description" },
    { "id": "n8", "type": "assign_team",   "team_id": 12 },
    { "id": "n9", "type": "add_label",     "label": "damage" },
    { "id": "n10","type": "delay",         "seconds": 3600 },
    { "id": "n11","type": "handoff_workflow", "workflow_definition_id": 44 },
    { "id": "n12","type": "handoff_agent" },
    { "id": "n13","type": "captain_answer" },
    { "id": "n14","type": "webhook_call",  "url": "...", "response_mapping": { "order_id": "$.data.id" } },
    { "id": "n15","type": "resolve" }
  ],
  "edges": [
    { "from": "n2", "to": "n3",  "match": { "type": "button", "value": "damage" } },
    { "from": "n2", "to": "n11", "match": { "type": "button", "value": "fines" } },
    { "from": "n4", "to": "n8",  "match": { "type": "condition",
        "conditions": [{ "attribute_key": "market", "filter_operator": "equal_to", "values": ["Australia"] }] } },
    { "from": "n4", "to": "n9",  "match": { "type": "fallback" } }
  ]
}
```

- Node action types map 1:1 to existing primitives (§2 table). Branch `conditions` reuse the automation-rules condition shape (`{attribute_key, filter_operator, values}`) so `AutomationRules::ConditionsFilterService`'s operator vocabulary (from `lib/filters/filter_keys.yml`) is reused, not reinvented.
- Edge matching order: `button` (exact `submitted_values` match) → `condition` (top-to-bottom, first match — Intercom semantics) → `fallback`.

### A.3 Runtime

```
app/services/workflows/trigger_service.rb   — picks the definition, creates the execution
app/services/workflows/runner_service.rb    — the graph walker
app/jobs/workflows/advance_job.rb           — MutexApplicationJob wrapper (all advancement goes through it)
app/jobs/workflows/wake_sweep_job.rb        — cron sweep for delay nodes
app/listeners/workflow_listener.rb          — async-dispatcher subscriber
```

**Trigger path** (`WorkflowListener#conversation_created`, `#message_created`):
- `conversation_created`: `WorkflowDefinition.where(inbox_id:, status: :live, trigger_type: :conversation_created).order(:priority).first` → **only the top match fires** for `customer_facing`; **all** `background` definitions fire (Intercom ordering semantics). Creates execution with `flow_snapshot: definition.flow` (correction #4).
- `message_created`: skip unless `message.incoming?` and not activity (mirror `AutomationRuleListener#ignore_message_created_event?`, correction #10); enqueue `Workflows::AdvanceJob`.
- New trigger while an execution is active → mark existing `interrupted`, start new (Intercom: one flow per conversation, new trigger interrupts).

**Concurrency** (correction #1): `Workflows::AdvanceJob < MutexApplicationJob`, key `WORKFLOW_RUNNER::<account_id>::<conversation_id>`, explicit `timeout: 15.seconds` (default 1s is too short for webhook/captain nodes), `retry_on_lock_conflict`. The partial unique index is the DB backstop.

**Ownership** (correction #2): extend `Inbox#active_bot?` → `super || workflow_active?` via `prepend`-style module in OSS (`Inbox.prepend_mod_with` chain untouched; this is an OSS feature so a direct concern include). Conversations start `pending` when a live workflow exists; every runner tick guards `return unless conversation.pending?` (Captain's `response_builder_job.rb:15` pattern). Manual agent assignment naturally kills the flow.

**Walk loop** (`RunnerService#advance(message = nil)`):
1. Load active execution (locked). If `message`: match against outgoing edges of `current_node_id` — read `message.content_attributes['submitted_values']` first, fall back to `message.content` (correction #7).
2. Execute nodes sequentially — `send_*` via `Messages::MessageBuilder.new(nil, conversation, { content:, content_type:, content_attributes: { items: }, sender: workflow_agent_bot })`; `set_attribute` writes `contact.custom_attributes` / `conversation.custom_attributes`; `assign_*`/`add_label`/`resolve` call the same model methods `AutomationRules::ActionService` uses.
3. Stop at any input-wait node (`send_buttons`, `collect_input`, `send_form`) — persist `current_node_id`, append to `steps`, touch `last_activity_at`.
4. `delay` → set `wake_at`; short delays (< 5 min) also enqueue `AdvanceJob.set(wait:)` with `(execution_id, expected_node_id)` no-op token; `WakeSweepJob` (sidekiq-cron, every minute, `config/schedule.yml`) sweeps `wake_at <= now` (correction #5).
5. `handoff_agent` → `conversation.bot_handoff!` (frees reporting, correction #3) → execution `handed_off`.
6. `handoff_workflow` → mark `completed`, create new execution for target definition (snapshot again).
7. `captain_answer` → EE hook point via `prepend_mod_with('Workflows::RunnerService')` — delegates the conversation to the inbox's Captain assistant; OSS no-ops.
8. `webhook_call` → reuse `Webhooks::Trigger` HTTP plumbing; map response into `variables` via JSONPath-lite (`Hash#dig` on parsed body); success/fail edges.

**Events**: dispatch `WORKFLOW_EXECUTION_COMPLETED` / `_HANDED_OFF` (new constants in `lib/events/types.rb`) so future reporting/webhooks subscribe without touching the runner.

### A.4 API (dashboard)

```
GET/POST/PATCH/DELETE /api/v1/accounts/:account_id/workflows          (CRUD + reorder: PATCH { priority_order: [ids] })
GET                   /api/v1/accounts/:account_id/workflows/:id/executions   (paginated, status filter)
POST                  /api/v1/accounts/:account_id/workflows/:id/duplicate
```
Controller under `Api::V1::Accounts::WorkflowsController`; Pundit policy `administrator` (mirror `settings/automation` permissions). `before_action :check_feature_enabled` (`workflows` flag).

### A.5 UI

**Phase A-UI-1 (ships with runtime): list + JSON editor.**
- Route `accounts/:accountId/settings/workflows` — `settings.routes.js` pattern, `meta: { featureFlag: FEATURE_FLAGS.WORKFLOWS, permissions: ['administrator'] }`.
- Vuex module `store/modules/workflows.js` (records + uiFlags, mirroring `campaigns.js`); API client `api/workflows.js`.
- Screens: list with drag-to-reorder (priority), status toggle (draft/live), duplicate; a guarded JSON editor (`components-next/Editor`) with server-side flow validation errors surfaced inline.
- i18n: `dashboard/i18n/locale/en/workflow.json`.

**Phase A-UI-2: visual canvas.**
- **New dependency: `@vue-flow/core`** (+ `@vue-flow/background`, `@vue-flow/controls`) — verified absent from package.json; MIT; Vue-3-native; the only new FE dependency in this entire plan.
- `routes/dashboard/settings/workflows/Builder.vue`: node palette (one Vue component per node type under `components-next/Workflows/nodes/`), edge editing with match-type popover, variable picker (reuses `CustomAttributes` components), live preview pane rendering widget bubbles (`AgentMessageBubble` components are shared/importable).
- Canvas serializes to exactly the §A.2 JSONB — the runtime never knows a canvas exists.

**Widget:** zero changes. `input_select`/`form`/`cards` rendering + `submitted_values` PATCH loop already exist (`AgentMessageBubble.vue`, `widget/api/message.js`). `collect_input` free-text uses plain messages.

---

## 5. Workstream B — Tickets

### B.1 Data model

**Migration 4 — `create_ticket_types`:**

```ruby
create_table :ticket_types do |t|
  t.references :account, null: false, index: true
  t.string  :name, null: false                       # "Damage", "Trip Issues", ...
  t.integer :category, default: 0, null: false      # customer: 0, back_office: 1, tracker: 2
  t.string  :icon, default: ''
  t.jsonb   :field_schema, default: []               # [{name, type(text|list|number|boolean|date|file),
                                                     #   options[], required_on_create, required_on_close,
                                                     #   customer_visible}] — max 50 entries (model validation)
  t.integer :status, default: 0, null: false         # active: 0, archived: 1
  t.timestamps
end
add_index :ticket_types, [:account_id, :name], unique: true
```

**Migration 5 — `create_tickets`:**

```ruby
create_table :tickets do |t|
  t.references :account, null: false, index: true
  t.references :ticket_type, null: false, index: true
  t.references :conversation, index: true            # nullable — back-office/tracker tickets may have none
  t.references :contact, index: true
  t.references :assignee, index: true                 # references users
  t.references :team, index: true
  t.integer :display_id, null: false                  # per-account sequence via hairtrigger (below)
  t.string  :title, null: false
  t.text    :description
  t.integer :state, default: 0, null: false           # submitted: 0, in_progress: 1, waiting: 2, resolved: 3
  t.jsonb   :custom_attributes, default: {}
  t.datetime :resolved_at
  t.timestamps
end
add_index :tickets, [:account_id, :display_id], unique: true
add_index :tickets, [:account_id, :ticket_type_id, :state]
```

**Ticket numbering** — the house hairtrigger pattern (`conversation.rb:382`): per-**account** sequence (`tick_dpid_seq_<account_id>`), created by an accounts `after_insert` trigger migration + backfill for existing accounts, consumed by `trigger.before(:insert)` on Ticket. *(Per-type sequences are possible — `tick_dpid_seq_<account>_<type>` created on ticket_type insert — but per-account matches Chatwoot precedent and Intercom itself numbers globally; decided: per-account.)*

**Migration 6 — `create_ticket_links`** (Tracker aggregation): `ticket_id`, `conversation_id`, unique composite index. Cross-post = iterate links, `Messages::MessageBuilder` private note per conversation.

### B.2 Backend

```
app/models/ticket.rb, ticket_type.rb, ticket_link.rb
app/services/tickets/create_from_form_service.rb    — form submitted_values → Ticket (+ field_schema validation)
app/listeners/ticket_listener.rb                    — TICKET_CREATED/TICKET_STATE_CHANGED events → webhooks/reporting
app/controllers/api/v1/accounts/tickets_controller.rb, ticket_types_controller.rb
```

- **State machine:** plain enum + `state_transition!` guard method (submitted→in_progress→waiting↔in_progress→resolved; customer reply on `waiting`/`resolved` auto-moves to `in_progress` via `WorkflowListener`-style message hook). No gem — minimal.
- **Inline widget creation:** workflow `send_form` node (Workstream A) with `content_attributes: { ticket_type_id: }` → on `submitted_values` PATCH, `Tickets::CreateFromFormService` creates the ticket + confirmation message. **Zero widget changes** — `ChatForm.vue` already renders and submits.
- **SLA pause on `waiting`:** EE hook — `Ticket.prepend_mod_with('Ticket')` pauses `applied_sla` (mirrors snooze handling).
- **Go-live bridge (labels-light):** before this workstream lands, Drive lah runs on labels (`damage`, `trip-issue`, …) + automation rules → team routing. The importer (§14) backfills labels → tickets.

### B.3 UI

- `settings/ticketTypes` — type list + field-schema builder (reuse `CustomAttributes` form components; `components-next/table`, `dialog`, `input`).
- Ticket views: new route `accounts/:accountId/tickets` — list (state/type filters, `components-next/table` + `tabbar`) + detail panel; conversation sidebar card "Linked ticket" (mirror `Conversation/Sla` card placement).
- Vuex `store/modules/tickets.js`; i18n `en/ticket.json`.

---

## 6. Workstream C — Email Campaigns + Goal Tracking

### C.1 Data model

**Migration 7 — additive columns on `campaigns`:**

```ruby
add_column :campaigns, :goal_event_name, :string
add_column :campaigns, :goal_window_hours, :integer, default: 168
add_column :campaigns, :processed_contacts_count, :integer, default: 0
add_column :campaigns, :failed_contacts_count, :integer, default: 0
```

**Migration 8 — `create_campaign_conversions`:**

```ruby
create_table :campaign_conversions do |t|
  t.references :account, null: false, index: true
  t.references :campaign, null: false
  t.references :contact, null: false
  t.timestamps
end
add_index :campaign_conversions, [:campaign_id, :contact_id], unique: true   # one conversion per contact
```

**Migration 9 — `create_email_suppressions`** (unsubscribes/bounces): `account_id`, `email` (citext), `reason` enum (unsubscribed/hard_bounce/spam), unique `[account_id, email]`.

### C.2 Backend

```
app/services/email/oneoff_campaign_service.rb   — mirrors Whatsapp::OneoffCampaignService shape
app/jobs/campaigns/email_delivery_job.rb        — per-batch sender, queue_as :low
app/controllers/api/v1/accounts/campaigns/conversions_controller.rb
app/controllers/public/api/v1/unsubscribe_controller.rb   — signed-GlobalID unsubscribe link
```

- **Dispatch:** extend `Campaign#execute_campaign`'s `inbox_type` case with `'Email' => Email::OneoffCampaignService` — the only touch to an existing file, a one-line case addition. Existing `trigger!`/`mark_processing!` `with_lock` dedup is inherited.
- **Scale (150K recipients):** the WhatsApp inline `contacts.each` loop does NOT scale to 150K. Instead: `process_audience` runs `contacts.tagged_with(labels, any: true).where.not(email: nil)` `.find_in_batches(batch_size: 500)` → one `Campaigns::EmailDeliveryJob` per batch (300 jobs for 150K — trivial for Sidekiq). Each job: skip suppressed emails, render Liquid per contact, send via existing SMTP/SendGrid mailer plumbing (`ConversationReplyMailer` SMTP config reused via a new lean `CampaignMailer`), increment counters with `update_counters`. Per-contact rescue → `failed_contacts_count`. SendGrid free-tier rate: throttle by `EmailDeliveryJob` concurrency (dedicated `low` queue is already last-drained).
- **Compliance:** `List-Unsubscribe` header + footer link (signed GlobalID → `unsubscribe_controller` → suppression row). Suppression check on every send.
- **Goals:** `POST /campaigns/:id/conversions { identifier | email }` (agent-token or platform-token authed; Drive lah's backend calls on booking-confirmed). Guard: contact must have received the campaign (join on processed set — store per-contact receipt in `campaign_conversions`-adjacent `steps`? — minimal: check `contact.additional_attributes['campaigns_received']` stamped at send). Goal rate = conversions ÷ processed, computed in the show serializer; window enforced by comparing `created_at`.

### C.3 UI

Clone the campaign triad (`components-next/Campaigns/Pages/CampaignPage/`): `EmailCampaign/EmailCampaignsPage.vue` + `EmailCampaignDialog.vue` + `EmailCampaignForm.vue`; route `campaigns/email` in `campaigns.routes.js` with `meta.featureFlag: FEATURE_FLAGS.EMAIL_CAMPAIGNS`; store getter `getEmailCampaigns` (filter `inbox.channel_type === 'Channel::Email'`); form fields: email inbox select, subject, rich body (`components-next/Editor`), audience labels, schedule, goal event name. Campaign detail gains a stats strip (processed/failed/conversions). i18n additions to `en/campaign.json`.

---

## 7. Workstream D — Surveys

Generalize CSAT into arbitrary surveys, reusing widget primitives.

**Migration 10 — `create_surveys` + `create_survey_responses`:**

```ruby
create_table :surveys do |t|
  t.references :account, null: false, index: true
  t.string  :name, null: false
  t.integer :status, default: 0                      # draft/live/archived
  t.jsonb   :questions, default: []                  # [{id, type(nps|star|emoji|select|text), label,
                                                     #   options[], save_to_attribute, branch_rules[]}] — max 12
  t.integer :delivery, default: 0                    # manual: 0, post_resolve: 1, campaign: 2
  t.timestamps
end

create_table :survey_responses do |t|
  t.references :account, null: false, index: true
  t.references :survey, null: false, index: true
  t.references :contact, null: false
  t.references :conversation, index: true
  t.jsonb :answers, default: {}                      # {question_id => value}
  t.datetime :completed_at
  t.timestamps
end
```

**Backend:** `Surveys::SendService` renders each question as an existing content type (`nps/star/emoji/select` → `input_select` items; `text` → plain message w/ `collect_input` semantics) — delivered as a **workflow** under the hood (a Survey compiles to a `WorkflowDefinition` flow — one engine, no second runtime). `post_resolve` delivery hooks `CONVERSATION_RESOLVED` in a `SurveyListener`, mirroring `CsatSurveyListener`. Answers with `save_to_attribute` write `contact.custom_attributes`. NPS score computed in a report serializer (promoters − detractors).

**UI:** `settings/surveys` list + question builder (reuse `input`, `select`, `radioCard` kit components); response explorer table. CSAT remains untouched — surveys are additive alongside it.

---

## 8. Workstream E — Events Tracking

**Migration 11 — `create_contact_events`:**

```ruby
create_table :contact_events do |t|
  t.references :account, null: false
  t.references :contact, null: false, index: true
  t.string :name, null: false
  t.jsonb  :metadata, default: {}                    # ≤10 keys (model validation, Intercom-canonical)
  t.datetime :created_at, null: false                # no updated_at — immutable event rows
end
add_index :contact_events, [:account_id, :name, :created_at]
add_index :contact_events, [:contact_id, :name]
```

**Backend:** ingestion via `POST /api/v1/accounts/:id/contacts/:contact_id/events` (agent/bot token) + widget endpoint `POST /api/v1/widget/events` (existing widget auth resolves contact). Immutable, insert-only; monthly partition **deferred** until volume demands (plan the table name now, partition later — additive). Consumers: campaign `trigger_rules` gains `event_name` support (evaluated in audience resolution), workflow `branch` conditions gain `event_count` operator. Retention: `housekeeping` cron purge > 12 months.

**UI:** contact-detail "Events" timeline tab (read-only list) — small.

---

## 9. Workstream F — Captain Extensions (EE)

All under `enterprise/`, gated by existing `captain_integration_v2` flag.

**Migration 12 — `create_captain_guidances` + `create_captain_custom_answers`:**

```ruby
create_table :captain_guidances do |t|
  t.references :account, null: false, index: true
  t.references :captain_assistant, null: false, index: true
  t.integer :category, default: 0        # style/clarification/content/spam/other (Intercom's 5)
  t.text    :content, null: false        # ≤2500 chars (model validation, Intercom-parity)
  t.boolean :enabled, default: true
  t.timestamps
end
# ≤100 enabled per account — model validation

create_table :captain_custom_answers do |t|
  t.references :account, null: false, index: true
  t.references :captain_assistant, null: false, index: true
  t.string  :question, null: false
  t.text    :answer, null: false
  t.boolean :enabled, default: true
  t.timestamps
end
```

**Backend:** `Guidance` items concatenate into the assistant's system prompt (hook: the existing prompt builder in `captain/llm/*` service — one insertion point). `CustomAnswer` check runs **before** generation: embed the incoming question, cosine-match against custom answers (reuse `article_embedding` pgvector plumbing), threshold hit → return the deterministic answer verbatim. Copilot: extend `copilot_thread` context window to include recent resolved conversations for the same contact + macro texts (data already in Postgres — retrieval addition, no schema).

**Topic clustering (from REV-49 P5):** `Captain::TopicClassificationJob` (`scheduled_jobs`) on `CONVERSATION_RESOLVED` → LLM-classify transcript against account topic list → apply `label`. Config = a `topics` string-array on assistant settings JSONB — no new table.

**UI:** two new tabs in `settings/captain` (guidance list, custom answers CRUD) using existing captain settings components.

---

## 10. Workstream G — SSO Hardening (EE)

**Migration 13 — `add_enforce_sso_to_account_saml_settings`:**

```ruby
add_column :account_saml_settings, :enforce_sso, :boolean, default: false, null: false
```

**Backend:** extend `SamlAuthenticationHelper#saml_user_attempting_password_auth?` — currently returns true only when `user.provider == 'saml'`; add: true when ANY of the user's accounts has `saml_settings.enforce_sso?` (existing sessions-controller guard then rejects password login and the FE surfaces the SSO redirect). ~1 file + specs.

**SCIM (deferred phase):** `enterprise/app/controllers/scim/v2/users_controller.rb` — bearer-token (new `scim_token` on `account_saml_settings`), SCIM 2.0 core schema, POST/PATCH/DELETE → `AccountUser` create/update/`update(active: false)`. No UI beyond a token-reveal row in `settings/security`.

**UI:** one toggle in the existing SAML settings card.

---

## 11. Workstream H — Reporting (Metabase)

Zero Chatwoot code. Deploy Metabase (Render private service) → read-only Postgres role (`GRANT SELECT` on reporting tables: `conversations`, `messages`, `reporting_events`, `csat_survey_responses`, `campaign_conversions`, `tickets`, `workflow_executions`). Build: bot-vs-human funnel (from `reporting_events` `conversation_bot_handoff` + `bot_resolved` names — same source as `BotMetricsBuilder`), Drive lah's 40 scheduled reports (Metabase native email subscriptions), campaign goal dashboards. The new tables in this plan (`workflow_executions.steps`, `tickets`, `campaign_conversions`, `contact_events`) were **designed with Metabase-queryable shapes** (flat columns + indexed timestamps) so no ETL is needed.

---

## 12. Small Extensions

| Change | Touch | Size |
|---|---|---|
| Macro team scope | `add_column :macros, :team_id` (nullable ref) + visibility scope + form select | XS |
| Widget Home cards | `channel_web_widget` JSONB `home_config` + widget `Home.vue` card list (article search card exists) | S (deferred) |
| Help Center redirects | `add_column :portals, :redirects, :jsonb, default: {}` + lookup in portal controller 404 path | XS |
| Sad-reaction → conversation | article feedback hook → `ConversationBuilder` | XS |
| Per-locale publish badge | FE-only, helpcenter locale switcher | XS |

---

## 13. Migration Inventory & Ordering

All additive; each group independently deployable & reversible (`change` methods auto-reverse; hairtrigger triggers regenerate from model annotations).

| # | Migration | Workstream | Depends on | Notes |
|---|---|---|---|---|
| 1 | `create_workflow_definitions` | A | — | |
| 2 | `create_workflow_executions` | A | 1 | partial unique index (plain — new empty table) |
| 3 | *(model-only)* AgentBot `bot_type: :workflow` | A | — | enum append, no DDL |
| 4 | `create_ticket_types` | B | — | |
| 5 | `create_tickets` + account sequence trigger | B | 4 | hairtrigger + backfill `create sequence` for existing accounts |
| 6 | `create_ticket_links` | B | 5 | |
| 7 | `add_goal_columns_to_campaigns` | C | — | additive columns w/ defaults — safe on live table |
| 8 | `create_campaign_conversions` | C | 7 | |
| 9 | `create_email_suppressions` | C | — | |
| 10 | `create_surveys` + `create_survey_responses` | D | 1 (compiles to workflows) | |
| 11 | `create_contact_events` | E | — | insert-only, no updated_at |
| 12 | `create_captain_guidances` + `create_captain_custom_answers` | F | — | EE; lives in `db/migrate` (Chatwoot keeps EE migrations in main tree) |
| 13 | `add_enforce_sso_to_account_saml_settings` | G | — | |

Deploy rules: run each group with its code behind a disabled feature flag; flags flip per-account after verification. `campaigns` column additions (7) use defaults so no backfill lock; everything else is new tables. No `disable_ddl_transaction!` needed except if index-adding later on hot tables.

---

## 14. Intercom → Chatwoot Data Migration

One-time import from Drive lah's Intercom workspace. Tooling: rake tasks under `lib/tasks/intercom_import.rake` hitting Intercom's REST API (cursor pagination, ≤150/page, 10k req/min budget — export ~483K contacts ≈ 3.3K requests).

| Data | Volume | Path | Notes |
|---|---|---|---|
| Contacts (users+leads) | 483K | Intercom Contacts API → `Contact` upsert (`identifier` = Intercom `external_id`, email, phone, `custom_attributes.market` from Intercom CDA) | batch 500/insert_all with conflict target `(account_id, identifier)`; pre-create `custom_attribute_definitions` first |
| Companies | small | Companies API → EE `company` | after contacts (association pass) |
| KB articles | 270 | Articles API → `portal`/`category`/`article` (per-brand portal) | then Captain ingest (REV-43 covers) |
| Open conversations | small | Conversations API (state=open) → `channel/api` inbox conversations with mapped contact + transcript as messages | only OPEN at cutover; agents finish them in Chatwoot |
| Historical conversations | ~190K/yr | **Not imported into Chatwoot.** Export → S3 (JSONL) → Metabase external table for lookup | keeps `messages` table lean; searchable where it's needed (reporting) |
| Tickets (closed) | 67,734 | Export CSV → S3/Metabase only | history is reporting, not operations |
| Tickets (open) | small | → new `Ticket` rows (after Workstream B) or labels-light conversations at cutover | |
| Attribute definitions | ~dozens | manual audit → `custom_attribute_definition` seeds | Market, account_type, booking ids first |

Cutover sequence: (1) contacts + attributes import → (2) widget/HMAC switch in Drive lah app (REV-34) → (3) open-conversation import the night of cutover → (4) Intercom to read-only.
Idempotency: every task keyed on Intercom IDs stored in `contact.additional_attributes['intercom_id']` — reruns upsert, never duplicate.

## 15. Testing Strategy

- **Models:** validations + state machines (`spec/models/workflow_definition_spec.rb`, `ticket_spec.rb`, …). Flow-size validator edge cases.
- **Runner (the critical suite):** `spec/services/workflows/runner_service_spec.rb` — table-driven: each node type; button/condition/fallback edge matching incl. `submitted_values`; interrupt semantics; snapshot isolation (edit definition mid-run → execution unaffected); lock contention (two concurrent `AdvanceJob`s → second no-ops); `pending?` guard (agent takeover kills flow); wake-sweep resume.
- **Campaign email:** batch fan-out counts, suppression skip, unsubscribe roundtrip, conversion dedup (unique index race).
- **Enterprise:** mirrored under `spec/enterprise/` (guidance prompt insertion, custom-answer match threshold, enforce_sso login rejection) — per CLAUDE.md, compare `error.class.name` in reloading env.
- **FE:** builder serialization round-trip (canvas → JSONB → canvas); campaign form specs alongside existing SMS form specs pattern.
- **Load check before Drive lah cutover:** seed via `rails search:setup_test_data`, fire 1K concurrent widget conversations against a live workflow (k6), assert lock queue depth + p95 advance latency < 500ms.

## 16. Phased Delivery Plan

Dependencies flow downward; each phase independently shippable behind its flag.

| Phase | Delivers | Contents | Unblocks |
|---|---|---|---|
| **P1** | Workflow runtime | Migrations 1–3, listener, runner, jobs, API, JSON-editor UI (A-UI-1). Drive lah's 32 flows authored as JSON | Drive lah bot parity |
| **P2** | Canvas builder | `@vue-flow/core`, Builder.vue, node components (A-UI-2) | Grace self-serve editing |
| **P3** | Tickets | Migrations 4–6, models/services, settings + ticket views, inline form via workflow node. Labels-light bridge retired | Damage/Trip/Tracker parity |
| **P4** | Email campaigns + goals | Migrations 7–9, delivery pipeline, conversions endpoint, EmailCampaign UI triad | 150K sends + goal rates |
| **P5** | Surveys + events | Migrations 10–11, survey-compiles-to-workflow, ingestion APIs | NPS + behavior targeting |
| **P6** | Captain ext + SSO | Migrations 12–13 (EE), guidance/custom answers, topic clustering, enforce_sso | Fin-guidance parity |
| **P7** | Reporting + data migration | Metabase, `intercom_import.rake`, cutover runbook (§14) | Go-live |

P1 is the critical path (everything Drive lah-visible depends on it); P3/P4 can run in parallel after P1; P7 overlaps all.

## 17. Risk Register

| Risk | Mitigation (built into design) |
|---|---|
| Concurrent messages corrupt execution state | Mutex job + partial unique index (A.3) |
| Definition edit breaks in-flight conversations | `flow_snapshot` per execution |
| Redis loss orphans delay timers | `wake_at` column + cron sweep, not bare `perform_in` |
| 150K email send melts worker / trips SendGrid | batch jobs on last-drained `low` queue + suppression + counters; k6 load check |
| features.yml reorder corrupts all accounts' flags | append-only rule stated in every migration PR description |
| EE/OSS drift | placement table (§3) + `prepend_mod_with` hooks only |
| Flow JSONB unbounded growth | custom size validator (100 nodes / 200KB) |
| Import duplicates on rerun | Intercom-ID keyed upserts |
| Widget regressions | zero widget changes in P1–P4 (reply loop already shipped) |

---

*Written July 2026 against Chatwoot `develop` @ `e8edc9ebf`. All file references verified in-repo. Estimates intentionally omitted per PRD convention — sequencing and dependency truth live here; scheduling lives in Linear (`REV-49`).*
