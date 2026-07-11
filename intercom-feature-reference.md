# Intercom → Chatwoot Feature Reference & Extension Map

> **Purpose.** An exhaustive, engineer-facing reference of Intercom's full product surface (verified against Intercom's official docs, 2026), each feature mapped to what Chatwoot has **today** and the concrete **extension path** to reach parity. Built for the Drive lah / Drivemate migration (see `REV-49`), but written to be reusable for any Chatwoot-as-Intercom-alternative build.
>
> **How to read this.** Every feature carries a status tag and, where relevant, the Chatwoot model/service/file to build against:
> - ✅ **EXISTS** — Chatwoot has it (OSS unless marked EE).
> - 🟡 **PARTIAL** — a foundation exists; needs extension.
> - 🔴 **GAP** — nothing today; net-new build.
> - 🏢 **EE** — lives in Chatwoot's Enterprise overlay (`enterprise/`).
> - 🚫 **NOT-CHATWOOT** — belongs in Drive lah's own app layer, not the helpdesk.
>
> **Grounding.** Chatwoot facts are read from this repo (models under `app/models`, `enterprise/app/models`; services under `app/services`; report builders under `app/builders/v2/reports`). Intercom facts are cited to official docs. Items Intercom's own docs left ambiguous are flagged **[unverified]** and must not be treated as settled.

---

## Table of Contents

1. [Parity Summary Matrix](#1-parity-summary-matrix)
2. [Team Inbox & Conversations](#2-team-inbox--conversations)
3. [Tickets](#3-tickets)
4. [Macros, Canned Responses, Saved Replies](#4-macros-canned-responses-saved-replies)
5. [SLAs, Assignment & Workload](#5-slas-assignment--workload)
6. [AI — Fin Agent, Copilot, Inbox AI](#6-ai--fin-agent-copilot-inbox-ai)
7. [Workflows / Bots / Automation](#7-workflows--bots--automation)
8. [Outbound — Email, Chat, Push, Series](#8-outbound--email-chat-push-series)
9. [Outbound — Banners, Carousels, Tooltips, Tours, Surveys, News](#9-outbound--banners-carousels-tooltips-tours-surveys-news)
10. [Help Center / Knowledge Base](#10-help-center--knowledge-base)
11. [The Messenger (Chat Widget)](#11-the-messenger-chat-widget)
12. [Reporting & Analytics](#12-reporting--analytics)
13. [Data / People Platform](#13-data--people-platform)
14. [Developer Platform — API, Webhooks, Canvas Kit, SDKs](#14-developer-platform)
15. [Identity & Security — HMAC, SSO, SCIM, Permissions](#15-identity--security)
16. [Channels — WhatsApp, SMS, Social, Phone](#16-channels)
17. [Drive lah Usage Map](#17-drive-lah-usage-map)
18. [Build Priority for Drive lah](#18-build-priority-for-drive-lah)
19. [Unverified / Flagged Facts](#19-unverified--flagged-facts)

---

## 1. Parity Summary Matrix

High-level scorecard. Detailed mapping in each section.

| Area | Intercom | Chatwoot today | Verdict |
|---|---|---|---|
| Team inbox, states, priority, assignment | Full | `conversation` (open/resolved/pending/snoozed), priority, assignment, teams | ✅ near-parity |
| Notes, mentions, participants | Full | `note`, `mention`, `conversation_participant` | ✅ |
| Tickets (types/states/custom fields) | Full formal model | Conversations + `label` only | 🔴 no ticket model |
| Macros | Content + actions | `macro` (content + actions) | ✅ |
| Canned responses / saved replies | Macro (text) | `canned_response` | ✅ |
| SLAs | 4 metrics, office hours | `sla_policy`, `applied_sla`, `sla_event` 🏢 | ✅ EE |
| Assignment: round-robin / balanced | Both + capacity | Auto-assign + `agent_capacity_policy` 🏢 | 🟡 balanced-ish |
| AI agent (Fin) | RAG + actions + guidance | Captain assistant + RAG docs + tools 🏢 | 🟡 strong base |
| AI copilot | Agent-assist | Captain `copilot_thread` 🏢 | 🟡 |
| Inbox AI (summarize/rephrase) | Full | Partial (Captain) | 🟡 |
| Workflows visual builder | Full canvas | `automation_rule` (flat IF/THEN) + `agent_bot` | 🔴 no visual multi-step engine |
| Bot messages (buttons/cards/forms) | Full | `content_type`: input_select, cards, form, article | 🟡 primitives exist |
| Email campaigns | Full | `campaign` (has one_off/ongoing; SMS+WA services only) | 🟡 no email sender |
| In-app / chat outbound | Full | `campaign` ongoing (widget) | 🟡 |
| Push (mobile) | Full campaign | FCM for notifications only | 🔴 no push campaign |
| Series (orchestration) | Visual multi-step | — | 🔴 |
| Banners (product) | Web overlay | `platform_banner` is super-admin only | 🔴 |
| Mobile carousels | SDK-only | — | 🚫 Drive lah app layer |
| Tooltips / Product Tours | Web | — | 🔴 (low priority) |
| Surveys | Full survey builder | CSAT only (`input_csat`, `csat_survey_response`) | 🔴 beyond CSAT |
| News / Newsfeed | Messenger + web | — | 🔴 |
| Help Center | Full | `portal`, `category`, `article`, `kbase` | ✅ near-parity |
| Messenger widget | Spaces + Home apps | `channel/web_widget` (simpler) | 🟡 no Home/spaces |
| Reporting | Datasets → charts | `reporting_event` + fixed report builders | 🟡 no custom builder |
| Bot-vs-human metrics | Full | `bot_metrics_builder` | ✅ |
| AI topic clustering | ML topics | — | 🔴 |
| Scheduled report delivery | Snapshot email | — | 🔴 (use Metabase) |
| People / contacts | visitor/lead/user | `contact` + `contact_inbox` | ✅ |
| Companies | Full | `company` 🏢 | ✅ EE |
| Events tracking | Full | limited | 🔴 |
| Custom attributes | contact/company/conv | `custom_attribute_definition` | ✅ |
| Segments | Saved dynamic | `custom_filter` (saved filters) | 🟡 |
| Custom Objects | Full data model | — | 🔴 |
| Tags | person + conversation | `label` (conversation), contact labels | 🟡 |
| REST API | Full | Full (`/api/v1`, platform API) | ✅ |
| Webhooks | Topics + HMAC-SHA1 | `webhook` model | ✅ |
| Canvas Kit | Server-driven UI | `dashboard_app` (iframe) | 🟡 iframe only |
| SDKs (web/iOS/Android/RN) | Full | Web + mobile SDKs | ✅ |
| Identity verification (HMAC) | HMAC-SHA256 / JWT | `identifier_hash` HMAC-SHA256 | ✅ (see REV-34) |
| SSO / SAML | Expert plan | `account_saml_settings` 🏢 | ✅ EE |
| SCIM | Full | — | 🔴 |
| Custom roles / permissions | Granular | `custom_role` 🏢 | ✅ EE |

---

## 2. Team Inbox & Conversations

### Conversation state machine
- **Intercom:** exactly **3 states** — Open, Snoozed, Closed. Snooze auto-reopens on timer expiry or customer reply (with an assignee-reply exception). ([Inbox explained](https://www.intercom.com/help/en/articles/6258745-the-inbox-explained))
- **Chatwoot:** `conversation.status` has **4** — `open`, `resolved`, `pending`, `snoozed`. `pending` (bot/awaiting) is an extra Chatwoot has that Intercom lacks; Intercom's Closed ≈ Chatwoot `resolved`.
- ✅ **EXISTS.** Near-parity, richer state set. Snooze auto-reopen exists via `Conversations::ActivityMessageJob`/reopen logic.

### Priority
- **Intercom:** 5 levels — None/Low/Medium/High/Urgent; set manually, via workflows, rules, macros; feeds assignment ordering.
- **Chatwoot:** `conversation.priority` — `low/medium/high/urgent` (+ nil). Same 5-level model.
- ✅ **EXISTS.**

### Views / filters
- **Intercom:** saved **Views** (real-time saved filters), plus table layout with configurable columns.
- **Chatwoot:** `custom_filter` (saved filters per user), `folder` (saved conversation filters/views). Conversation list has filters.
- ✅ **EXISTS** via `custom_filter` + `folder`.

### Notes vs replies, mentions, reactions
- **Intercom:** internal notes with `@mention` (teammate or whole team), emoji reactions on notes, independent draft buffers for reply vs note.
- **Chatwoot:** `note` model, `mention` model, private messages (`message.private = true`). Reactions on messages exist.
- ✅ **EXISTS.**

### Participants / CC / BCC (group conversations)
- **Intercom:** To/Cc/Bcc; Bcc not counted as participants; auto-add CC'd replier.
- **Chatwoot:** `conversation_participant` model; email CC/BCC via `Conversations::` email handling.
- ✅ **EXISTS** (`conversation_participant`), with email cc/bcc on email channel.

### Collision detection & "side conversations"
- **Intercom:** presence indicators only (no true locking). "Side conversations" are **not** a native Intercom feature — the analog is back-office tickets + notes. ([research flagged])
- **Chatwoot:** typing/presence indicators exist. No locking.
- ✅ **PARITY** (both rely on presence, not locking). Not a gap to chase.

### Conversation attributes & tags
- **Intercom:** custom conversation attributes; conversation tags (per-message granularity).
- **Chatwoot:** `custom_attribute_definition` (conversation-scoped), `label` (conversation labels). Chatwoot labels are conversation-level, not per-message.
- 🟡 **PARTIAL** — per-message tagging is finer in Intercom; rarely needed.

---

## 3. Tickets

**This is the single biggest structural gap.** Intercom has a first-class Ticket object; Chatwoot models everything as a `conversation`.

### Intercom's ticket model
- **3 categories:** **Customer** (customer-facing, auto-shares progress), **Back-office** (internal, optionally shareable), **Tracker** (internal, aggregates many linked conversations, broadcasts mass updates). ([Tickets explained](https://www.intercom.com/help/en/articles/6436600-tickets-explained))
- **State machine — 4 required categories,** each with ≥1 (custom-nameable) state: **Submitted → In progress → Waiting on customer → Resolved.** "Waiting on customer" can pause SLAs. ([Ticket states](https://www.intercom.com/help/en/articles/9730130-how-ticket-states-work))
- **Ticket types** define captured fields + category. Default Title + Description; add custom attributes (Text/List/Number/Decimal/Boolean/Date/File). Per-attribute: customer-visible, required-for-create, required-for-close, conditional logic. **Limits:** 50 attributes/type; format immutable; 1,000 CSV list options. ([Ticket types](https://www.intercom.com/help/en/articles/7112127-how-to-set-up-ticket-types))
- **Inline ticket creation in Messenger** — customer self-creates from Messenger Home ticket links; or teammate/workflow sends a ticket form. ([Create tickets in Messenger](https://www.intercom.com/help/en/articles/8395778-create-tickets-in-the-messenger))
- **Tickets portal** — logged-in users see their company's tickets/conversations in the Help Center (needs custom domain + identity verification + company association).

### Chatwoot today
- No `Ticket` model. Conversations + `label` + `custom_attribute_definition` approximate it. `form` content-type message exists for structured collection.
- 🔴 **GAP.**

### Extension path
**Light (days) — labels-as-types:**
- Labels `damage`, `trip-issue`, `customer`, `back-office`, `tracker`; `automation_rule` routes label → team. Loses ticket numbers, mandatory fields, formal states.

**Full (2–3 weeks) — new `Ticket` model:**
- New table: `account_id`, `conversation_id` (nullable), `ticket_type_id`, `ticket_number` (per-type sequence), `state_id`, `custom_attributes` JSONB.
- `TicketType` + `TicketState` (4-category enum) models.
- Reuse the existing **`form` message content type** for the inline Messenger form (already in `message.rb` enum) → on submit, create Ticket + persist fields to `custom_attributes`.
- Ticket inbox view = new Vue route filtering conversations by ticket association.
- Portal = extend `portal` (Help Center) with an authenticated "my tickets" view keyed on contact + `company`.
- **Tracker** = a Ticket with a `links` join to many conversations + a cross-post note action (reuse `note` broadcast).

> Drive lah has **5 ticket types, 67,734 tickets** and uses **inline "Damage – Create Ticket"** forms → this gap is on the Drive lah critical path. Start light for go-live, build full in parallel. (`REV-49` Phase 3.)

---

## 4. Macros, Canned Responses, Saved Replies

- **Intercom:** a **Macro** = content **+ actions** (assign, tag, snooze, close, reopen, change priority, set ticket state, data-connector API call). Constraints: can't mix reply+note, can't mix snooze+close; placeholders fill only in single-participant convos. Scopes: personal / team (Expert plan) / workspace. "Snippets" are a **separate** Knowledge-Hub object feeding AI, **not** composer macros. ([Macros](https://www.intercom.com/help/en/articles/6433193-creating-and-managing-macros))
- **Chatwoot:**
  - `canned_response` = text saved replies (the "saved reply" analog), inserted with `/shortcode`.
  - `macro` = content **+ actions** (assign, label, priority, resolve, etc.), scoped personal/global. Very close to Intercom macros.
- ✅ **EXISTS.** `macro` + `canned_response` cover both. Minor gaps: team-scoped macros (Chatwoot has personal/global, not per-team), and macro "set custom ticket state" (blocked until a Ticket model exists).
- **Extension:** add `team_id` scope to `macro` if team-scoping is wanted (small).
- **Snippets:** Chatwoot's Captain uses `document`/FAQ for AI knowledge — the equivalent of Intercom snippets is Captain FAQ docs, not canned responses. Keep the distinction.

---

## 5. SLAs, Assignment & Workload

### SLAs
- **Intercom:** 4 metrics — **First Response Time, Next Response Time, Time to Close, Time to Resolution.** Office-hours-aware (targets in calendar hours, consumed against office hours; holidays skipped; pause on snooze/waiting-without-extending-deadline). One active SLA/conversation, newest wins. Applied via workflows. ([SLAs](https://www.intercom.com/help/en/articles/6546152-set-slas-for-conversations-and-tickets))
- **Chatwoot 🏢 EE:** `sla_policy` (first_response_time_threshold, next_response_time_threshold, resolution_time_threshold, only_during_business_hours), `applied_sla`, `sla_event`. `working_hour` powers office hours.
- ✅ **EXISTS (EE).** Chatwoot has FRT/NRT/resolution + business-hours. Missing an explicit "Time to Close vs Time to Resolution" split and holiday-skip nuance; close enough.

### Assignment
- **Intercom:** per-inbox method — **Balanced** (fewest open, respects limits), **Round robin** (rotation, ignores limits), **Manual**. Assignment ordering by priority → SLA → waiting-since → started-at. Capacity via Workload Management (individual + inbox limits). ([Workload management](https://www.intercom.com/help/en/articles/6560715-workload-management-explained))
- **Chatwoot:**
  - Auto-assignment (round-robin style) via `inbox` auto-assignment + `Conversations::` assignment services.
  - 🏢 `agent_capacity_policy`, `inbox_capacity_limit`, `assignment_policy`, `inbox_assignment_policy` — capacity-based assignment.
- 🟡 **PARTIAL → strong.** Chatwoot has auto-assign + capacity policies (EE). "Balanced vs round-robin as an explicit per-inbox toggle" and Intercom's exact ordering chain aren't 1:1 but the primitives exist. Extension: expose an assignment-strategy enum + ordering config on the inbox/policy.

---

## 6. AI — Fin Agent, Copilot, Inbox AI

Chatwoot's **Captain** (EE) is the direct analog to Fin. It is already RAG-based with a tool-calling action layer — the strongest "gap" area is actually well-covered.

### Fin AI Agent (customer-facing)
- **Intercom:** bespoke RAG in 3 phases (Refine query → Retrieve+augment+generate → Validate/ground). Sources: public/internal articles, snippets, PDFs, public URL crawl, synced KBs (Zendesk/Confluence/Guru/Notion), past conversations (Copilot only). **Guidance** (natural-language behavior shaping, max 100 items/2500 chars). **Custom Answers** (deterministic overrides). **Tasks/Procedures** (multi-step API actions with data connectors, webhook-pause, idempotency keys). 45+ languages, omnichannel. Resolution = confirmed (explicit) or assumed (24h silence); billed $0.99/resolution. ([Fin AI Engine](https://www.intercom.com/help/en/articles/9929230-the-fin-ai-engine))
- **Chatwoot 🏢 Captain:**
  - `captain/assistant` + `assistant_response` — the AI agent.
  - `captain/document` + `article_embedding` (**pgvector/IVFFlat**) — RAG retrieval. URL crawl via Firecrawl.
  - `captain/tools/*` — action layer: `faq_lookup`, `handoff`, `http_tool` (≈ data connector), `resolve_conversation`, `add_label_to_conversation`, `update_priority`, `add_private_note`, `add_contact_note`.
  - `captain/scenario` — sub-agent behaviors (≈ a lighter Guidance/Procedures).
  - `captain/custom_tool` — user-defined tools.
  - `assistant_false_promise_schema` / false-promise harness — guardrail against ungrounded promises (≈ Intercom's validation phase).
- 🟡 **STRONG BASE.** Covers RAG + retrieval + tool-calling + handoff + a guardrail. **Gaps vs Fin:** (1) no formal "Guidance" library UI (partially covered by `scenario`); (2) no deterministic "Custom Answers" override object; (3) actions layer is simpler than Data-connector Procedures (no webhook-pause/idempotency step type); (4) resolution-rate accounting (hard vs soft) not as formalized.
- **Extension:** add a `Captain::Guidance` model (behavior rules), a `Captain::CustomAnswer` (exact-match deterministic reply), and a webhook-pause tool for multi-step async actions.

> Drive lah: **270 knowledge articles** ingest into `captain/document`; `handoff_tool` for human escalation. This is `REV-43`.

### Fin AI Copilot (agent-facing)
- **Intercom:** in-inbox assistant; superset knowledge incl. **past conversations + macros (4 months)**; direct answer + sources; add-to-composer/modify/translate; save-as-macro. $29/agent/mo.
- **Chatwoot 🏢:** `copilot_thread` + `copilot_message` — agent-assist threads.
- 🟡 **PARTIAL.** Base exists; extend knowledge sources to include past conversations + macros; add "insert to composer / rephrase / translate" composer actions.

### Inbox AI (compose/summarize)
- **Intercom:** AI Compose (expand/rephrase/tone/grammar/translate), AI Summarize (note), AI Autofill (ticket title/desc), Smart Replies, Auto-translation.
- **Chatwoot:** Captain-powered reply suggestions / rephrase exist in the composer (EE integrations); summarize partial.
- 🟡 **PARTIAL.** Extend Captain composer helpers to cover the full expand/rephrase/tone/summarize set.

### AI Insights / Topic clustering
- **Intercom:** Topics Explorer (ML clusters conversations into topics/subtopics, seeded on 90 days, daily pipeline; subtopic needs ≥15 questions). Trends, CX Score, Monitors/Scorecards.
- **Chatwoot:** `captain/message_report`; no clustering.
- 🔴 **GAP.** Extension: Sidekiq job on conversation-resolve → embed transcript → cluster (or LLM-classify) → apply `label`. ~3–5 days for LLM-classify; clustering pipeline is larger. (`REV-49` Phase 5.)

---

## 7. Workflows / Bots / Automation

**Second-biggest gap.** Intercom's **Workflows** is a full visual, stateful, multi-step conversation engine. Chatwoot has `automation_rule` (flat, single-shot IF/THEN) + `agent_bot` (external bot via webhook). No native visual multi-step flow builder.

### Intercom Workflows
- **Visual canvas:** trigger block + message/action/condition nodes connected by paths. ([Workflows builder](https://www.intercom.com/help/en/articles/6611595-using-the-workflows-builder))
- **8 message types:** Send Bot Message, Collect Data (→ attribute), Collect Customer Reply (free text), **Reply Buttons** (quick replies), **Let Fin Answer**, Show Expected Reply Time, **Send Ticket** (form), Send an App (Canvas Kit).
- **Action steps:** tag/untag (person + conversation), assign, snooze, wait/delay, mark priority, apply SLA, **Data connector (API)**, close, **disable customer reply**, set conversation data. ⚠️ Date attributes can't be set by a step.
- **Triggers:** new conversation opened, first message, any message (background), button click, page visit/element click (outbound), inactivity, ticket created, teammate actions, phone call, schedule, **reusable** (invoked). ([Triggers](https://www.intercom.com/help/en/articles/7434613-how-to-trigger-a-workflow))
- **Priority/ordering:** customer-facing = **only the top match fires** (list order = priority, drag to reorder); background = **all match, run in parallel.** One workflow per conversation at a time (new trigger interrupts). ([Ordering](https://www.intercom.com/help/en/articles/7857645-managing-the-order-of-your-workflows))
- **Branching:** Branch node, strict top-to-bottom first-match; conditions on person/company/message/conversation/availability data. Multi-level via nested branches + reply-button paths.
- **Sub-workflow handoff:** "Pass to Reusable Workflow" (interrupts current).
- **Data connectors + Custom Objects:** call external APIs mid-flow, map response → attributes/objects, success/fail paths, "Buttons from Custom Objects" (one button per instance).

### Chatwoot today
- `automation_rule` — event-triggered (`conversation_created`, `conversation_updated`, `message_created`) IF/THEN with conditions + actions (assign, label, team, priority, resolve, webhook, etc.). **Single-shot, not stateful, no branching, no waiting on customer input.**
- `agent_bot` + `agent_bot_inbox` — register an external bot that receives conversation webhooks and replies via API. This is the escape hatch for real conversational flows.
- **Message primitives already present** in `message.rb` `content_type`: `input_select` (quick-reply buttons), `cards`, `form`, `article`, `input_email/text/textarea`. So the **rendering** side of bot steps largely exists.
- 🔴 **GAP** on the engine; 🟡 **PARTIAL** on the building blocks.

### Extension path — a native workflow engine (from `REV-49`)
```
WorkflowDefinition   — JSONB {nodes, edges, variables}, inbox_id, priority
WorkflowExecution    — current_node_id, variables, status  (state per conversation)
WorkflowRunnerService— graph walker: load execution → eval edges → advance → act
MessageCreated hook  — on customer message, resume the active execution
```
- **Node → primitive mapping (mostly reuse):**
  - Send message → `Conversations::ReplyService`
  - Reply Buttons / Collect Reply → `content_type: input_select` (exists)
  - Send Ticket form → `content_type: form` (exists)
  - Send an App → `dashboard_app` / card (partial)
  - Set attribute → `contact.custom_attributes` / conversation attrs (exists)
  - Assign / tag / snooze / priority / resolve → existing `automation_rule` actions (exist)
  - Data connector → `webhook` + response-mapping layer (build the mapping UI)
  - Let Captain answer → Captain handoff (exists)
- **Ordering semantics to replicate:** customer-facing "first match only" (new class of rule that stops after first), background "all run" (today's automation behavior).
- **Visual builder** = Phase 2 Vue canvas (e.g. Vue Flow). Runtime is agnostic to how JSON is authored.
- **Alternative:** external **Typebot** via `agent_bot` webhook (faster, separate service). Trade-off documented in `REV-32` / `REV-49`.

> Drive lah: **32 workflows, 9-button menus, multi-level branching, "Set Market to [Region]", sub-workflow handoff (Fine nomination v3), inline images.** All map to the node set above. Critical path.

---

## 8. Outbound — Email, Chat, Push, Series

### Shared model (build this first)
- **Intercom:** every outbound message shares **Content / Audience-rules (When-Where-Who) / Goal**. **Dynamic** audience (ongoing) vs **Fixed** audience (one-off). Audience re-check is **polling-based** (hourly for email; 30 min in Series), not real-time except transactional. ([Message rules](https://www.intercom.com/help/en/articles/5296455-message-rules-when-how-and-to-whom-should-a-message-be-sent))
- **Chatwoot:** `campaign` model already has `campaign_type {ongoing, one_off}`, `audience` (JSONB), `trigger_rules` (JSONB), `scheduled_at`, `trigger_only_during_business_hours`. This **is** the shared spine.
- 🟡 **PARTIAL** — spine exists; channels are limited (see below).

### Email campaigns
- **Intercom:** one-off (fixed) / ongoing (dynamic) / triggered (event/date). Visual + HTML editors (switch is destructive), merge tags, subscription types, deliverability review, auto-exclude unsubscribed/bounced. ([Outbound email](https://www.intercom.com/help/en/articles/3292845-get-started-with-outbound-emails))
- **Chatwoot:** `campaign` supports one_off/ongoing, but sending services exist only for **SMS** (`sms/oneoff_sms_campaign_service`, `twilio/oneoff_sms_campaign_service`) and **WhatsApp** (`whatsapp/oneoff_campaign_service`). **No email campaign sender.**
- 🔴 **GAP (email channel).** Extension: add `Email::OneoffCampaignService` mirroring the WhatsApp one, Sidekiq bulk-send via SendGrid (already configured), audience filter → per-contact enqueue. ~2–3 weeks. **OR** external Customer.io/Brevo pulling segments via API (faster). (`REV-49` Phase 4.)

> Drive lah sends **150,528-recipient** email blasts, AU + SG separately. This is Phase 4.

### Chat / in-app (Messenger) outbound
- **Intercom:** proactive Chat (two-way) and Post (announcement), Badge/Snippet/Full styles, targeting by attribute/behavior/URL.
- **Chatwoot:** `campaign` ongoing type renders in the widget (`widget/views/Campaigns.vue`, `campaignHelper.js`) — proactive widget messages exist.
- 🟡 **PARTIAL/EXISTS** for basic proactive widget messages. Post-style announcements/reactions are thinner.

### Mobile push
- **Intercom:** one-way push campaigns via SDK (APNs/FCM), deep links, targeting.
- **Chatwoot:** FCM is used for **agent/user notifications**, not as an outbound **campaign** channel.
- 🔴 **GAP (push as campaign).** Extension: add a push channel to `campaign` + `Push::OneoffCampaignService`. Note carousels/banners (below) are the higher-value mobile formats and are Drive lah-app-owned.

### Series (orchestration)
- **Intercom:** visual multi-step journey builder — 4 node types (**Rule / Content / Wait / Tag**) + entry/exit rules, "match once" vs "match for X time" branches, up to-5-path split tests, control groups, tags as cross-series glue, 30-min processing cadence. ([Series](https://www.intercom.com/help/en/articles/4425207-series-explained))
- **Chatwoot:** none.
- 🔴 **GAP.** Large build; shares the workflow-engine graph runtime (§7) if built natively. Lower priority than transactional bot flows unless Drive lah needs lifecycle journeys.

### Goals, A/B, control groups, subscriptions
- **Intercom:** Goal = attribute/event change, diff-checked, time-windowed, **excludes pre-converted** users. A/B = 2 variants, manual winner, no stat-sig. Control = 50/50 holdout, requires a goal. Subscription types (opt-in/opt-out lists) power granular unsubscribe + a preference center.
- **Chatwoot:** none of goal-tracking / A/B / control / subscription-types.
- 🔴 **GAP.** Extension: add `goal_event` to `campaign` + a `POST /campaigns/:id/conversions` endpoint (Drive lah's app calls it on booking-confirmed). Subscription types = new model + unsubscribe preference page.

> Drive lah tracks **goal rates** (email 0.16–21.95%, carousel 38%, banner 28.59%). The conversion endpoint is the minimum viable slice.

---

## 9. Outbound — Banners, Carousels, Tooltips, Tours, Surveys, News

| Format | Intercom platform | Chatwoot | Verdict |
|---|---|---|---|
| **Banners** | Web overlay (top/bottom, inline/floating) | `platform_banner` is super-admin only | 🔴 GAP (product banners) |
| **Mobile Carousels** | **SDK-only**, full-screen swipe cards | — | 🚫 Drive lah app layer |
| **Tooltips** | Web, anchored to elements | — | 🔴 (low priority) |
| **Product Tours** | Desktop web, multi-step | — | 🔴 (low priority) |
| **Surveys** | Small/large, 8 question types, branching | CSAT only | 🔴 beyond CSAT |
| **News / Newsfeed** | Messenger + public News Center | — | 🔴 |

### Detail & guidance
- **Banners:** Intercom banners are marketing/announcement overlays on the customer's site with CTA/reaction/email-collect/goal. Chatwoot's `platform_banner` is an internal super-admin notice, **not** this. 🔴 GAP; build as a widget-delivered banner tied to `campaign` if needed.
- **Mobile Carousels** (Drive lah's **38% goal-rate** format) & **Banners** in-app: these render in Drive lah's **React Native app**, triggered by their backend (FCM). 🚫 **NOT-CHATWOOT** — Drive lah engineering owns them; Chatwoot webhook events can be the trigger signal. Documented as out-of-scope in `REV-49`.
- **Surveys:** Chatwoot has **CSAT only** (`input_csat` content type, `csat_survey_response`, `csat_survey_service`). Intercom's general survey builder (NPS, star, emoji, multiple-choice, branching, store-answer-as-attribute) is a 🔴 GAP. Extension: generalize the CSAT survey into a `Survey`/`SurveyQuestion` model reusing `input_*` content types.
- **Tooltips / Product Tours:** web-app onboarding overlays. 🔴 GAP, **low priority** for a support-tool migration — Drive lah doesn't rely on these per the Intercom audit.
- **News:** Messenger newsfeed + public News Center. 🔴 GAP; could be modeled as a special `article`/`campaign` hybrid. Low priority.

---

## 10. Help Center / Knowledge Base

Chatwoot has a genuine Help Center; this is a ✅ near-parity area.

- **Intercom:** Collections → Sections → Sub-collections → Articles (3-level). Multiple Help Centers (≤100), custom domains (CNAME, subdomain/subpath), SEO (canonical, OG, noindex, GA4), **Manage Redirects**, 64-language multilingual (manual, per-locale color-coded publish state), public/user-only audiences, article reactions (sad → auto-conversation), article insights (views/reactions/conversations-started). Feeds Fin. ([Help Center explained](https://www.intercom.com/help/en/articles/56640-help-center-explained))
- **Chatwoot:**
  - `portal` (a Help Center), `category` + `related_category` (nesting), `article`, `kbase`, `folder`.
  - Multiple portals (≈ multiple help centers), custom domain per portal, locales per portal/article, article `views` count.
  - Articles feed **Captain** via `captain/document` ingestion.
- ✅ **EXISTS / near-parity.** Worth-copying gaps: (1) **Manage Redirects** UI, (2) sad-reaction → auto-conversation loop, (3) article→conversations reporting, (4) per-locale publish-state color-coding, (5) 3rd-level nesting depth. All small extensions on existing models.

> Drive lah's **270 articles** live here and double as Captain's RAG source (`REV-43`).

---

## 11. The Messenger (Chat Widget)

- **Intercom:** widget organized into **spaces** (Home / Messages / Tickets / Help / News / Tasks). Highly configurable **Home** with reorderable **apps/cards** (1–19, audience-ruled). Compact/standard layouts, light/dark/system theme, launcher position/visibility rules (URL/attribute/geo, AND/OR, `hide_default_launcher`), business-hours reply expectations, identity verification, upfront email capture, multi-brand. ([Messenger explained](https://www.intercom.com/help/en/articles/6612588-messenger-explained))
- **Chatwoot:** `channel/web_widget` — color, position, launcher, pre-chat form (upfront capture), business hours (`working_hour`), reply-time, HMAC identity, allowed domains, multi-inbox (≈ multi-brand). **No "spaces" tab model, no configurable Home with cards.**
- 🟡 **PARTIAL.** Core customization + pre-chat + identity + business-hours all exist. **Gap:** the spaces/Home-apps UX (biggest UX delta). Extension: a widget Home screen with configurable cards (article search, news, ticket links, Canvas-style apps) — sizeable frontend build. Pre-chat form + HMAC + business hours already cover Drive lah's must-haves.

---

## 12. Reporting & Analytics

- **Intercom:** **Datasets (13) → metrics/attributes → charts (9 types) → reports (dashboards).** 12 prebuilt templates. Custom builder (100+ chart templates, AND/OR filters at chart+report level, breakdowns, aggregations, drill-in to conversations). **Scheduled delivery** = read-only snapshot link email (30-day expiry), not PDF. CSV export (10k rows instant). ([Custom report](https://www.intercom.com/help/en/articles/4549035-create-a-custom-report))
- **Chatwoot:**
  - `reporting_event` + `reporting_events_rollup` (event store), `report_metric_registry`, and a suite of **fixed** builders under `app/builders/v2/reports/`: `agent_summary`, `team_summary`, `inbox_summary`, `label_summary`, `inbox_label_matrix`, `first_response_time_distribution`, `outgoing_messages_count`, `channel_summary`, and **`bot_metrics_builder`** (bot vs human).
  - CSAT reporting via `csat_survey_response`.
- 🟡 **PARTIAL.** Strong fixed reports + bot metrics + CSAT. **Gaps:** no drag-and-drop custom report builder, no scheduled delivery, no AI topic clustering.
- **Extension / recommendation:** **Metabase** on Chatwoot's Postgres read replica gives the custom builder + scheduled email delivery + the bot-vs-human "Sankey-style" view with **zero Chatwoot code.** Recommended over building a custom report builder. (`REV-49` Phase 5.)

> **[unverified]** Intercom does **not** appear to offer a literal Sankey diagram — it uses KPI/donut/column charts + query-type buckets. Drive lah's "Sankey" is achievable in Metabase.

### Bot-vs-human & CSAT specifics
- `bot_metrics_builder` already tracks resolution_rate / handoff_rate / bot vs human counts → directly answers Drive lah's "32% bot / 64% teammate / 1% bot-resolved" need. ✅

---

## 13. Data / People Platform

- **Contacts:** Intercom visitor → lead → user progression, `user_id`-primary identity, lead→user merge. **Chatwoot:** `contact` + `contact_inbox` (per-inbox identity, `hmac_verified`), contact merge exists. ✅ **EXISTS.**
- **Companies:** Intercom companies with attributes/associations. **Chatwoot 🏢:** `company` model (EE). ✅ **EXISTS (EE).**
- **Custom attributes:** Intercom CDAs (4 types + list≤35, ~250 cap, immutable names, archive-not-delete) on contact/company/conversation. **Chatwoot:** `custom_attribute_definition` (contact + conversation scoped, typed). ✅ **EXISTS.**
- **Segments:** Intercom saved dynamic segments. **Chatwoot:** `custom_filter` (saved filters) + `label` groupings. 🟡 **PARTIAL** — saved filters exist; "dynamic segment membership auto-recompute for campaign audiences" is partial (campaign `audience` JSONB filters at trigger time).
- **Events:** Intercom custom event tracking (name/timestamp/metadata, event-based targeting). **Chatwoot:** limited event tracking. 🔴 **GAP** — extension: an `Event` model + ingestion API + event-based campaign triggers. Needed if Drive lah wants behavior-triggered outbound.
- **Custom Objects:** Intercom flexible data models (Orders, etc.) with references, used in workflows/Fin. **Chatwoot:** none. 🔴 **GAP** — large; only needed for rich "pick your order → act" bot flows.
- **Tags:** Intercom person + conversation (per-message) tags. **Chatwoot:** `label` (conversation + contact labels). 🟡 **PARTIAL** — no per-message tag granularity.

---

## 14. Developer Platform

- **REST API:** Intercom = cursor-paginated (≤150/page), regional hosts, versioned, 10k/min app rate limit. **Chatwoot:** full `/api/v1/accounts/...` + platform API (`platform_app`), page-number pagination. ✅ **EXISTS** (pagination style differs — shim needed only if emulating Intercom's API shape).
- **Webhooks:** Intercom = topic subscriptions, `X-Hub-Signature` **HMAC-SHA1** over body with `client_secret`, 5s response, 1 retry. **Chatwoot:** `webhook` model with subscribed events. ✅ **EXISTS** (signing scheme differs). Drive lah integration = `REV-37`.
- **Canvas Kit:** Intercom = **server-driven JSON UI** (`initialize`/`submit` request-response, `stored_data`, native components) rendered in Messenger **and** Inbox. **Chatwoot:** `dashboard_app` = **iframe** app in the agent sidebar (closer to Intercom **Sheets** than native Canvas). 🟡 **PARTIAL.** Extension: a webhook-driven card protocol for the widget Home + inbox sidebar to enable inline forms / third-party cards. Sizeable.
- **SDKs:** Intercom web/iOS/Android/RN/Cordova. **Chatwoot:** web widget SDK + iOS/Android/RN/Flutter SDKs. ✅ **EXISTS.** Drive lah uses the RN SDK (`REV-34`, `REV-41`).
- **App Store / integrations:** Intercom marketplace (Salesforce/HubSpot/Slack/Stripe/Jira). **Chatwoot:** `integrations` (Slack, Dialogflow, etc.) + `dashboard_app`. 🟡 **PARTIAL** — fewer prebuilt integrations; API/webhook parity lets clients build their own.

---

## 15. Identity & Security

- **Messenger identity verification:** Intercom = **HMAC-SHA256** over `user_id`/`email` with a secret (legacy `user_hash`), or JWT (HMAC-SHA256) — the recommended path. **Chatwoot:** `identifier_hash` = **HMAC-SHA256** on `identifier` with the channel HMAC key (`user_attribute_helpers.rb#hmac_identifier`, `channel/web_widget` `hmac_token`, `contact_inbox.hmac_verified`). ✅ **EXISTS** — maps to Intercom's legacy user_hash exactly. JWT path would be net-new. **This is `REV-34`.**
- **SSO / SAML:** Intercom = SAML SSO (Expert plan), JIT provisioning, enforce, Google sign-on, 2FA. **Chatwoot 🏢:** `account_saml_settings` (sso_url, certificate, idp_entity_id, sp_entity_id, role_mappings), `saml_user_builder`, `omniauth_saml`; Google OAuth in OSS. ✅ **EXISTS (EE).** Gaps: (1) **enforce-SSO / block password** (per-user `saml_user_attempting_password_auth?` exists but no account-level enforce flag — ~3-day build), (2) see SCIM below.
- **SCIM:** Intercom = SCIM 2.0 provisioning + group→role mapping. **Chatwoot:** none. 🔴 **GAP** — build a `/scim/v2/Users` endpoint (~2 weeks) or a nightly IdP sync job. Only needed if Drive lah wants IdP-driven agent lifecycle.
- **Permissions / roles:** Intercom = granular custom roles (Advanced/Expert), seat types. **Chatwoot 🏢:** `custom_role` (granular permissions). ✅ **EXISTS (EE).**

> SSO detail & Auth0/Supabase bridging options are in the `REV-32` gap comment.

---

## 16. Channels

All converge into one omnichannel inbox in both products.

| Channel | Intercom | Chatwoot | Verdict |
|---|---|---|---|
| **Email** (2-way) | Full, multi-domain/brand | `channel/email` | ✅ |
| **WhatsApp** | Paid add-on | `channel/whatsapp` | ✅ (Drive lah `REV-38`) |
| **SMS** | 2-way + campaigns | `channel/sms` (Twilio) | ✅ (Drive lah `REV-39`) |
| **Instagram** | DMs/mentions | `channel/instagram` | ✅ |
| **Facebook** | Page DMs | `channel/facebook_page` | ✅ |
| **Phone / Voice** | Intercom Phone (IVR, recording consent, AMD) | `call` model 🏢 (basic) | 🟡 partial |
| **Web widget** | Messenger | `channel/web_widget` | ✅ |
| **API channel** | — | `channel/api` (custom) | ✅ (Chatwoot extra) |

- ✅ **EXISTS** for all of Drive lah's channels (web, email, WhatsApp, SMS). Phone/voice is thinner in Chatwoot (EE `call` model) vs Intercom Phone's IVR/consent/AMD — not on Drive lah's path.

---

## 17. Drive lah Usage Map

Every confirmed Drive lah Intercom behavior → where it lands.

| Drive lah behavior | Feature area | Chatwoot path | Issue |
|---|---|---|---|
| 32 workflows, 9-button menus, branching | Workflows (§7) | Build workflow engine OR Typebot | REV-49 P2 |
| "Set Market to AU/SG" mid-flow | Workflow set-attribute | `contact.custom_attributes` node | REV-49 P2 |
| Sub-workflow handoff (Fine nomination v3) | Workflow handoff | switch `WorkflowDefinition` | REV-49 P2 |
| Bot images + step instructions | Bot rich message | `content_type` image+text | REV-49 P2 |
| 5 ticket types, 67,734 tickets | Tickets (§3) | labels (light) or `Ticket` model | REV-49 P3 |
| Inline "Damage – Create Ticket" form | Ticket inline form | `content_type: form` → Ticket | REV-49 P3 |
| 150K-recipient email blasts (AU+SG) | Email campaigns (§8) | `Email::OneoffCampaignService` or Customer.io | REV-49 P4 |
| Mobile carousel (38% goal) | Carousel (§9) | 🚫 Drive lah RN app | REV-49 out-of-scope |
| In-app banner (28.59% goal) | Banner (§9) | 🚫 Drive lah RN app | REV-49 out-of-scope |
| Goal/conversion rates | Goals (§8) | `goal_event` + conversions endpoint | REV-49 P4 |
| 40 reports + scheduled delivery | Reporting (§12) | Metabase | REV-49 P5 |
| Bot vs human 32/64/1% | Bot metrics (§12) | `bot_metrics_builder` ✅ | REV-49 P5 |
| AI topic clustering | AI Insights (§6) | Sidekiq + OpenAI → label | REV-49 P5 |
| 270 KB articles + Fin answering | Help Center + Captain (§6,§10) | `portal`/`article` + `captain/document` | REV-43 |
| HMAC widget identity | Identity (§15) | `identifier_hash` ✅ | REV-34 |
| Agent SSO | SSO (§15) | Google OAuth ✅ / SAML EE | REV-49 P6 |
| WhatsApp / SMS | Channels (§16) | `channel/whatsapp` / `channel/sms` ✅ | REV-38/39 |
| React Native SDK + push | SDK (§14) | RN SDK + FCM | REV-34/41 |
| Market-based routing | Automation | `automation_rule` on attribute → team ✅ | — |

---

## 18. Build Priority for Drive lah

Ordered by go-live criticality (detail in `REV-49`):

1. **Foundation (done):** account, inboxes, Market attribute, HMAC secret, webhook secret.
2. **Core integrations:** SendGrid (REV-36), webhook (REV-37), WhatsApp (REV-38), SMS (REV-39), auth (REV-40), FCM (REV-41), Captain + 270 articles (REV-43), Google OAuth. HMAC on Drive lah side (REV-34).
3. **Workflow engine (§7)** — the largest build; decision: native vs Typebot. Blocks bot parity.
4. **Tickets (§3)** — labels-light for go-live, `Ticket` model in parallel.
5. **Email campaigns (§8)** — Customer.io (fast) or native service.
6. **Reporting (§12)** — Metabase (zero Chatwoot code).
7. **AI topic clustering, goal tracking, SSO hardening** — post-launch.

**Already covered, no build:** channels, HMAC identity, Help Center, Captain RAG, companies, custom attributes, custom roles, SLAs, macros, CSAT, bot-vs-human metrics — all exist (OSS or EE).

---

## 19. Unverified / Flagged Facts

Do not treat these as settled; verify before building against them.

- **Sankey diagrams:** not confirmed as a native Intercom report type; Intercom uses KPI/donut/column + query-type buckets. Drive lah's "Sankey" → build in Metabase.
- **Fin foundation LLM vendor(s):** Intercom doesn't publicly name them; engine is multi-model.
- **Custom Answers follow-up-action config:** source page was auth-gated; details thin.
- **Event metadata limit:** Intercom docs cite both 10 and 20 keys; treat 10 as canonical.
- **Intercom regional API hosts / current top stable API version / full webhook topic list:** shift between API versions; re-verify against the live version-pinned reference.
- **Branch "otherwise/none-matched" fallback label:** exact behavior not verified from fetched docs.
- **Help Center custom-domain HTTP-only note:** outdated for current SSL-provisioned setups; verify.
- **Plan gating** (Advanced/Expert/Pro add-on) throughout: Intercom renames tiers frequently; treat as directional.

---

*Sources: Intercom official Help Center (`intercom.com/help`), Developer Platform (`developers.intercom.com`), and `fin.ai`, compiled July 2026. Chatwoot mappings read from this repository (`app/models`, `enterprise/app/models`, `app/services`, `app/builders/v2/reports`). Companion documents: `REV-32` (gap analysis), `REV-48` (parity map), `REV-49` (master PRD).*
