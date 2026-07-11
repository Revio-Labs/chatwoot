# Intercom Feature — Implementation Status Tracker

> Work-status tracker for every Intercom feature we intend to match in Chatwoot for the Drive lah / Drivemate migration. One row per feature: what it is, the status, and **both** the backend and UI/frontend work. Companion to `intercom-feature-reference.md` (deep detail) and `REV-49` (master PRD).

### Status legend

| Badge | Meaning |
|---|---|
| 🟢 **DONE (OSS)** | Shipped in Chatwoot open-source — backend **and** UI. Configure only. |
| 🟢 **DONE (EE)** | Shipped in Chatwoot Enterprise (`enterprise/`) — backend **and** UI. Enable/configure. |
| 🟡 **PARTIAL** | Foundation exists (backend and/or UI); needs extension to reach parity. |
| 🔵 **PLANNED** | Net-new build, scoped in the PRD, not started. |
| ⚪ **BACKLOG** | Gap, low priority for Drive lah — deferred. |
| 🚫 **OUT OF SCOPE** | Belongs to Drive lah's app layer or intentionally excluded. |

### How to read the two work columns
- **Backend** — Chatwoot model/service/file (Rails).
- **UI / Frontend** — Vue work: `✅ exists` (screen already built), `🟡 extend <route>`, `🔵 new <component/route>`, or `— none`. Dashboard routes live under `app/javascript/dashboard/routes/dashboard/…`; customer-facing screens under `app/javascript/widget/…`; shared components under `dashboard/components-next/…`.

---

## 1. Team Inbox & Conversations

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Conversation states | Open / resolved / pending / snoozed lifecycle, auto-reopen. | 🟢 DONE (OSS) | `conversation.status` | ✅ conversation view |
| Priority | 5-level priority, manual + automated. | 🟢 DONE (OSS) | `conversation.priority` | ✅ conversation header |
| Saved views / filters | Named saved filters + folders. | 🟢 DONE (OSS) | `custom_filter`, `folder` | ✅ `customviews`, filters |
| Notes & @mentions | Internal notes, mentions, reactions. | 🟢 DONE (OSS) | `note`, `mention` | ✅ composer (note mode) |
| Participants / CC-BCC | Group conversations + email cc/bcc. | 🟢 DONE (OSS) | `conversation_participant` | ✅ conversation sidebar |
| Presence / collision | "Who's viewing" presence indicators. | 🟢 DONE (OSS) | presence channels | ✅ conversation header |
| Conversation attributes | Custom typed attributes on a conversation. | 🟢 DONE (OSS) | `custom_attribute_definition` | ✅ `settings/attributes` + sidebar |
| Required-attrs on resolve | Force attributes filled before resolving. | 🟢 DONE (OSS) | conversation resolve | ✅ `settings/conversationWorkflow` |
| Per-message tagging | Tag an individual message. | 🟡 PARTIAL | `label` (conv-level) | 🟡 extend labels UI |

## 2. Tickets

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Ticket types (5) | Damage/Trip/Customer/Back-office/Tracker routing to teams. | 🔵 PLANNED | new `Ticket` model / labels-light | 🔵 new `settings/ticketTypes` + ticket inbox view |
| Ticket states | Submitted→In progress→Waiting→Resolved, custom states. | 🔵 PLANNED | new `TicketState` | 🔵 new state config UI |
| Ticket custom fields | Per-type fields, required, conditional logic. | 🔵 PLANNED | `Ticket.custom_attributes` | 🔵 new field-builder UI |
| Inline ticket form (widget) | Customer fills a form in chat to open a ticket. | 🔵 PLANNED | `content_type: form` → Ticket | 🔵 new widget form renderer (extend `Messages.vue`) |
| Tracker tickets | Aggregate many conversations + broadcast update. | ⚪ BACKLOG | `Ticket` + links | ⚪ tracker links panel |
| Tickets portal | Users see their company's tickets in Help Center. | ⚪ BACKLOG | extend `portal` | ⚪ portal "my tickets" view |

## 3. Macros / Canned Responses

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Canned responses | Text saved replies via `/shortcode`. | 🟢 DONE (OSS) | `canned_response` | ✅ `settings/canned` |
| Macros (content + actions) | Reusable template that runs actions. | 🟢 DONE (OSS) | `macro` | ✅ `settings/macros`, `conversation/Macros` |
| Team-scoped macros | Macros scoped to a team. | 🟡 PARTIAL | add `team_id` to `macro` | 🟡 extend `settings/macros` form |
| Snippets (AI knowledge) | Short Q&A feeding the AI agent. | 🟢 DONE (EE) | `captain/document` | ✅ `settings/captain` |

## 4. SLAs, Assignment & Workload

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| SLA policies | Response + resolution targets, business-hours aware. | 🟢 DONE (EE) | `sla_policy`, `applied_sla` | ✅ `settings/sla`, `Conversation/Sla` |
| Business hours | Office-hours config. | 🟢 DONE (OSS) | `working_hour` | ✅ `settings/inbox` business hours |
| Auto-assignment | Round-robin auto-assign. | 🟢 DONE (OSS) | inbox auto-assignment | ✅ `settings/inbox` collaborators |
| Capacity-based assignment | Per-agent / per-inbox limits. | 🟢 DONE (EE) | `agent_capacity_policy` | ✅ `settings/assignmentPolicy` |
| Balanced vs round-robin toggle | Explicit strategy + ordering. | 🟡 PARTIAL | extend `assignment_policy` | 🟡 extend `settings/assignmentPolicy` |

## 5. AI (Fin equivalent = Captain)

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| AI agent (customer-facing) | RAG chatbot answering from knowledge. | 🟢 DONE (EE) | `captain/assistant` | ✅ `dashboard/captain`, `settings/captain` |
| Knowledge RAG / embeddings | pgvector retrieval; URL crawl. | 🟢 DONE (EE) | `captain/document`, `article_embedding` | ✅ `settings/captain` documents |
| Action tools | Handoff, FAQ, HTTP, resolve, label, priority. | 🟢 DONE (EE) | `captain/tools/*` | ✅ captain tools UI |
| Human handoff | Escalate to a human with context. | 🟢 DONE (EE) | `handoff_tool` | ✅ captain config |
| False-promise guardrail | Blocks ungrounded commitments. | 🟢 DONE (EE) | `assistant_false_promise_schema` | ✅ account setting |
| AI Copilot (agent-assist) | In-inbox drafting assistant. | 🟡 PARTIAL | `copilot_thread` | 🟡 extend `components-next/copilot` |
| Guidance library | Natural-language behavior rules. | 🟡 PARTIAL | `captain/scenario` → `Guidance` | 🔵 new guidance UI |
| Custom Answers | Deterministic exact-wording overrides. | 🔵 PLANNED | new `Captain::CustomAnswer` | 🔵 new answers UI |
| Multi-step API tasks | Procedures w/ data-connector + webhook-pause. | 🔵 PLANNED | extend `custom_tool` | 🔵 new task builder |
| Inbox AI (rephrase/summarize) | Expand/rephrase/tone/translate + summarize. | 🟡 PARTIAL | Captain composer helpers | 🟡 extend reply composer |
| AI topic clustering | Auto-group conversations into topics. | 🔵 PLANNED | Sidekiq + OpenAI → `label` | 🔵 new topics report view |

## 6. Workflows / Bots

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Visual multi-step workflow engine | Stateful canvas of message/action/condition nodes. | 🔵 PLANNED | new `WorkflowDefinition` + `WorkflowExecution` + runner | 🔵 **new Vue Flow canvas builder** (biggest FE build) |
| Quick-reply buttons | Tappable button menus; disable free text. | 🟡 PARTIAL | `content_type: input_select` | 🟡 widget renders it; needs builder UI |
| Cards / rich bot messages | Card + image/text bot messages. | 🟢 DONE (OSS) | `content_type: cards` | ✅ widget `Messages.vue` |
| Inline form step | Structured form inside a flow. | 🟢 DONE (OSS) | `content_type: form` | ✅ widget form renderer |
| Set-attribute step | Write attribute mid-flow (Market=AU). | 🟡 PARTIAL | runner node → custom_attributes | 🔵 node config in builder |
| Multi-level branching | Nested condition nodes, first-match. | 🔵 PLANNED | runner graph walker | 🔵 branch nodes in builder |
| Sub-workflow handoff | Jump to another flow. | 🔵 PLANNED | switch `WorkflowDefinition` | 🔵 handoff node in builder |
| Workflow priority | Only top-matching flow fires. | 🔵 PLANNED | `priority` column | 🔵 drag-reorder list UI |
| Data-connector (API mid-flow) | Call external API, map response back. | 🟡 PARTIAL | `webhook` + mapping layer | 🔵 connector mapping UI |
| Flat automation rules | Single-shot IF/THEN on events. | 🟢 DONE (OSS) | `automation_rule` | ✅ `settings/automation` |
| External bot via webhook | Register a 3rd-party bot (Typebot). | 🟢 DONE (OSS) | `agent_bot` | ✅ `settings/agentBots` |

## 7. Outbound — Email / Chat / Push / Series

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Campaign spine | Ongoing vs one-off + audience/trigger rules. | 🟢 DONE (OSS) | `campaign` | ✅ `dashboard/campaigns` |
| Proactive in-app (widget) message | Live-chat campaign shown in widget. | 🟢 DONE (OSS) | `campaign` | ✅ `Campaigns/…/LiveChatCampaign` + widget `Campaigns.vue` |
| SMS campaigns | One-off SMS blasts. | 🟢 DONE (OSS) | `sms/oneoff_sms_campaign_service` | ✅ `Campaigns/…/SMSCampaign` |
| WhatsApp campaigns | One-off WhatsApp blasts. | 🟢 DONE (OSS) | `whatsapp/oneoff_campaign_service` | ✅ `Campaigns/…/WhatsAppCampaign` |
| Email campaigns | Bulk email blasts (150K+, AU+SG). | 🔵 PLANNED | new `Email::OneoffCampaignService` | 🔵 **new `Campaigns/…/EmailCampaign` page + editor** |
| Mobile push campaigns | One-way push as a campaign. | ⚪ BACKLOG | push channel on `campaign` | ⚪ new push campaign page |
| Series (journey orchestration) | Multi-step email→wait→in-app journeys. | ⚪ BACKLOG | reuse workflow runtime | ⚪ series canvas (reuse builder) |
| Goal / conversion tracking | Did the message drive the action. | 🔵 PLANNED | `goal_event` + conversions endpoint | 🔵 goal field on campaign form + report |
| A/B testing | 2-variant test, manual winner. | ⚪ BACKLOG | `campaign` variants | ⚪ variant UI |
| Control groups | 50/50 holdout to prove lift. | ⚪ BACKLOG | `campaign` holdout | ⚪ holdout toggle |
| Subscription types / unsubscribe | Granular opt-in/out + preference center. | ⚪ BACKLOG | new subscription model | ⚪ preference-center page |

## 8. Outbound — Product-side formats

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Banners (product) | Announcement/CTA overlay on customer's site. | ⚪ BACKLOG | widget-delivered banner | 🔵 widget banner renderer + config |
| Mobile carousels | Full-screen swipe cards in mobile app (38% goal). | 🚫 OUT OF SCOPE | — | 🚫 Drive lah RN app |
| In-app banner (mobile) | In-app overlay banner (28.59% goal). | 🚫 OUT OF SCOPE | — | 🚫 Drive lah RN app |
| Tooltips | Contextual pointers on web UI elements. | ⚪ BACKLOG | — | ⚪ — |
| Product tours | Guided web walkthroughs. | ⚪ BACKLOG | — | ⚪ — |
| Surveys (general) | NPS/star/emoji/multiple-choice + branching. | 🔵 PLANNED | generalize CSAT into `Survey` | 🔵 new survey builder + widget renderer |
| CSAT survey | Post-conversation rating. | 🟢 DONE (OSS) | `input_csat`, `csat_survey_response` | ✅ widget CSAT + `settings` |
| News / Newsfeed | In-Messenger announcements + public page. | ⚪ BACKLOG | — | ⚪ widget news space |

## 9. Help Center / Knowledge Base

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Help Center portals | Public hosted KB with custom domain. | 🟢 DONE (OSS) | `portal` | ✅ `dashboard/helpcenter` |
| Collections / nesting | Category hierarchy. | 🟢 DONE (OSS) | `category` | ✅ helpcenter categories |
| Articles | Authored KB articles + locales. | 🟢 DONE (OSS) | `article`, `kbase` | ✅ helpcenter editor |
| Articles feed the AI | KB ingested as AI knowledge. | 🟢 DONE (EE) | `captain/document` | ✅ `settings/captain` |
| Manage redirects | Old-slug → new-URL redirects. | ⚪ BACKLOG | extend `portal` | ⚪ redirects UI |
| Sad-reaction → conversation | Negative feedback opens a conversation. | ⚪ BACKLOG | reaction hook | ⚪ portal reaction wiring |
| Article → conversations report | Conversations an article generated. | ⚪ BACKLOG | reporting extension | ⚪ helpcenter insights |

## 10. Messenger (Chat Widget)

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Web chat widget | Embeddable customer chat. | 🟢 DONE (OSS) | `channel/web_widget` | ✅ `widget/` app |
| Widget customization | Colors, position, launcher, branding. | 🟢 DONE (OSS) | `channel/web_widget` | ✅ `settings/inbox` widget builder |
| Pre-chat form / email capture | Collect identity before chat. | 🟢 DONE (OSS) | web widget pre-chat | ✅ widget `PreChatForm.vue` |
| Business-hours reply time | Expected reply / away message. | 🟢 DONE (OSS) | `working_hour` | ✅ widget header |
| Multi-brand | Separate widget per brand (AU/SG). | 🟢 DONE (OSS) | multiple inboxes | ✅ per-inbox config |
| Home screen with cards/apps | Configurable Home with reorderable apps (spaces). | ⚪ BACKLOG | widget Home data | 🟡 extend widget `Home.vue` (basic Home exists) |

## 11. Reporting & Analytics

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Fixed reports | Agent/team/inbox/label summaries, FRT distribution. | 🟢 DONE (OSS) | `app/builders/v2/reports/*` | ✅ `dashboard/settings/reports` |
| Bot-vs-human metrics | Resolution/handoff rate, bot vs human. | 🟢 DONE (OSS) | `bot_metrics_builder` | ✅ reports UI |
| CSAT reporting | Satisfaction score. | 🟢 DONE (OSS) | `csat_survey_response` | ✅ CSAT report |
| SLA reporting | SLA hit/miss over time. | 🟢 DONE (EE) | `sla_event` | ✅ `reports/components/SLA` |
| Custom report builder | Drag-and-drop dashboards. | 🔵 PLANNED | Metabase (external) | 🔵 Metabase UI (no Chatwoot FE) |
| Scheduled report delivery | Auto-email reports (Drive lah's 40). | 🔵 PLANNED | Metabase (external) | 🔵 Metabase UI |
| Sankey / flow visual | Bot-vs-human flow chart. | 🔵 PLANNED | Metabase (external) | 🔵 Metabase UI |

## 12. Data / People Platform

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Contacts (visitor/lead/user) | Contact model + per-inbox identity. | 🟢 DONE (OSS) | `contact`, `contact_inbox` | ✅ `dashboard/contacts` |
| Companies | Company records + associations. | 🟢 DONE (EE) | `company` | ✅ `dashboard/companies` |
| Custom attributes | Typed custom fields. | 🟢 DONE (OSS) | `custom_attribute_definition` | ✅ `settings/attributes` |
| Segments | Saved dynamic filters as audiences. | 🟡 PARTIAL | `custom_filter` + `campaign.audience` | 🟡 extend filters UI |
| Event tracking | Custom events + event-based targeting. | ⚪ BACKLOG | new `Event` model | ⚪ events UI |
| Custom Objects | Flexible external data models. | ⚪ BACKLOG | — | ⚪ — |
| Tags / labels | Conversation + contact tagging. | 🟢 DONE (OSS) | `label` | ✅ `settings/labels` |

## 13. Developer Platform

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| REST API | Full CRUD API. | 🟢 DONE (OSS) | `/api/v1`, platform API | ✅ `settings/integrations` (API access) |
| Webhooks | Event push to external endpoints. | 🟢 DONE (OSS) | `webhook` | ✅ `settings/integrations` webhooks |
| SDKs (web/iOS/Android/RN) | Client SDKs incl. RN for Drive lah. | 🟢 DONE (OSS) | web + mobile SDKs | ✅ SDK (external apps) |
| Canvas Kit (server-driven UI) | Interactive cards in widget/inbox. | 🟡 PARTIAL | `dashboard_app` (iframe) | 🟡 extend dashboard-apps + widget cards |
| App Store / integrations | Prebuilt integration marketplace. | 🟡 PARTIAL | `integrations`, `dashboard_app` | 🟡 `settings/integrations` |

## 14. Identity & Security

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| HMAC identity verification | HMAC-SHA256 widget user verification. | 🟢 DONE (OSS) | `identifier_hash` | ✅ `settings/inbox` (HMAC token) |
| Google OAuth (agents) | Agent sign-in with Google. | 🟢 DONE (OSS) | omniauth google | ✅ login screen |
| SAML SSO (agents) | Enterprise SSO (Okta/Auth0/Azure). | 🟢 DONE (EE) | `account_saml_settings` | ✅ `settings/security` |
| SCIM provisioning | IdP-driven agent lifecycle. | ⚪ BACKLOG | new `/scim/v2` endpoint | ⚪ SCIM config UI |
| Custom roles / permissions | Granular permission roles. | 🟢 DONE (EE) | `custom_role` | ✅ `settings/customRoles` |

## 15. Channels

| Feature | What it is | Status | Backend | UI / Frontend |
|---|---|---|---|---|
| Web widget | Live chat channel. | 🟢 DONE (OSS) | `channel/web_widget` | ✅ inbox setup |
| Email (2-way) | Threaded email inbox. | 🟢 DONE (OSS) | `channel/email` | ✅ inbox setup |
| WhatsApp | WhatsApp Business (Drive lah). | 🟢 DONE (OSS) | `channel/whatsapp` | ✅ inbox setup |
| SMS | Two-way SMS (Drive lah). | 🟢 DONE (OSS) | `channel/sms` | ✅ inbox setup |
| Instagram / Facebook | Social DM channels. | 🟢 DONE (OSS) | `channel/instagram`, `channel/facebook_page` | ✅ inbox setup |
| Phone / voice | Voice channel with IVR/consent. | 🟡 PARTIAL | `call` (EE, basic) | 🟡 `components-next/call` |

---

## Rollup

| Status | Count (approx.) | Backend work | UI / Frontend work |
|---|---|---|---|
| 🟢 DONE (OSS/EE) | ~50 | none | none — screens exist |
| 🟡 PARTIAL | ~14 | small extensions | small screen extensions |
| 🔵 PLANNED | ~16 | scoped net-new (PRD P2–P6) | **includes 3 big FE builds** |
| ⚪ BACKLOG | ~15 | deferred | deferred |
| 🚫 OUT OF SCOPE | 2 | — | Drive lah RN app |

### Biggest UI/frontend builds (in priority order)
1. **Workflow canvas builder** (§6) — a Vue Flow drag-and-drop editor for nodes/edges. Largest single FE effort. Runtime is backend; this is the authoring surface.
2. **Ticket UI** (§2) — ticket-type/state/field config screens + a ticket inbox view + the inline widget form renderer.
3. **Email campaign page + editor** (§7) — a new `EmailCampaign` page beside the existing SMS/WhatsApp/LiveChat campaign pages, plus an email content editor.
4. **Survey builder** (§8) — generalize the CSAT config into a multi-question builder + widget renderer.
5. **Reporting** (§11) — delivered via **Metabase** (no Chatwoot frontend needed) rather than building a custom report builder.

### Already-built UI worth noting (no work)
Campaigns dashboard (SMS/WhatsApp/LiveChat pages), Captain (agent + settings + copilot), Macros, Canned responses, SLA config + reports, Automation rules, Agent Bots, Help Center editor, Contacts, Companies, Custom attributes, Labels, Custom roles, Security/SAML, Assignment policy, per-inbox widget builder, widget pre-chat form + CSAT + basic Home. These cover most of Drive lah's needs with configuration only.

---

*Critical-path net-new work (blocks go-live parity): Workflow engine + its canvas UI (§6), Ticket model + UI (§2), Email campaigns + page (§7). Detail and effort in `REV-49`.*
