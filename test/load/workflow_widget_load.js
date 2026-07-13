/* eslint-disable */
// k6 load test for the workflow engine, driven through the real widget API.
//
// It simulates Drive-lah-style host traffic: each virtual user boots a fresh
// widget session (self-serving its own auth token), opens a conversation, waits
// for the bot's welcome menu, and taps a button — exercising the full
// conversation.created -> workflow -> message chain under concurrency.
//
// Run:
//   k6 run \
//     -e CHATWOOT_URL=https://chatwoot-latest-n4ia.onrender.com \
//     -e WEBSITE_TOKEN=<your widget inbox website token> \
//     test/load/workflow_widget_load.js
//
// Tune load with -e VUS=200 -e DURATION=5m (or edit the stages below).
// See test/load/README.md for setup and the backend metrics to watch.

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';

const BASE = __ENV.CHATWOOT_URL;
const WEBSITE_TOKEN = __ENV.WEBSITE_TOKEN;
const BUTTON_VALUE = __ENV.BUTTON_VALUE || 'trip_issue';
const BOT_WAIT_MS = Number(__ENV.BOT_WAIT_MS || 8000);

// Time from opening the conversation to the bot's first interactive (buttons/form) reply.
const botResponse = new Trend('bot_response_time', true);
const botReplied = new Rate('bot_replied');
const botMissing = new Counter('bot_no_reply');

export const options = {
  scenarios: {
    hosts: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: __ENV.VUS
        ? [{ duration: __ENV.DURATION || '3m', target: Number(__ENV.VUS) }]
        : [
            { duration: '1m', target: 50 }, // warm up
            { duration: '3m', target: 300 }, // sustained peak
            { duration: '1m', target: 0 }, // ramp down
          ],
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'], // <1% HTTP errors
    http_req_duration: ['p(95)<3000'], // widget API p95 < 3s
    bot_response_time: ['p(95)<5000'], // bot replies within 5s at p95
    bot_replied: ['rate>0.98'], // >98% of conversations get a bot reply
  },
};

function widgetHeaders(authToken) {
  return { headers: { 'Content-Type': 'application/json', 'X-Auth-Token': authToken } };
}

function firstInteractiveMessage(messages) {
  return (messages || []).find(
    m => m.content_type === 'input_select' || m.content_type === 'form'
  );
}

export default function () {
  // 1. Boot a fresh widget session -> mints an auth token + a new contact_inbox.
  const config = http.post(
    `${BASE}/api/v1/widget/config?website_token=${WEBSITE_TOKEN}`,
    null
  );
  if (!check(config, { 'config 200': r => r.status === 200 })) return;
  const authToken = config.json('website_channel_config.auth_token');
  if (!authToken) return;

  // 2. Open a conversation with a first message -> fires the workflow.
  const openedAt = Date.now();
  const createRes = http.post(
    `${BASE}/api/v1/widget/conversations?website_token=${WEBSITE_TOKEN}`,
    JSON.stringify({ message: { content: 'Hello', timestamp: new Date().toISOString() } }),
    widgetHeaders(authToken)
  );
  check(createRes, { 'conversation created': r => r.status === 200 });

  // 3. Poll for the bot's interactive reply (welcome buttons / form).
  let interactive = null;
  const deadline = Date.now() + BOT_WAIT_MS;
  while (Date.now() < deadline) {
    sleep(0.5);
    const list = http.get(
      `${BASE}/api/v1/widget/messages?website_token=${WEBSITE_TOKEN}`,
      widgetHeaders(authToken)
    );
    if (list.status === 200) {
      interactive = firstInteractiveMessage(list.json('payload') || list.json());
      if (interactive) break;
    }
  }

  if (interactive) {
    botReplied.add(1);
    botResponse.add(Date.now() - openedAt);

    // 4. Tap a button on the bot's menu.
    http.patch(
      `${BASE}/api/v1/widget/messages/${interactive.id}?website_token=${WEBSITE_TOKEN}`,
      JSON.stringify({ message: { submitted_values: [{ value: BUTTON_VALUE, title: BUTTON_VALUE }] } }),
      widgetHeaders(authToken)
    );
  } else {
    botReplied.add(0);
    botMissing.add(1);
  }

  sleep(1);
}
