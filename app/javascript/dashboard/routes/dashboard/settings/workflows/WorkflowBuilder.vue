<script setup>
import { ref, computed, onMounted, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { VueFlow, useVueFlow, MarkerType } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import { MiniMap } from '@vue-flow/minimap';
import '@vue-flow/core/dist/style.css';
import '@vue-flow/core/dist/theme-default.css';
import '@vue-flow/controls/dist/style.css';
import '@vue-flow/minimap/dist/style.css';

import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import FlowNode from './FlowNode.vue';
import NodePropertiesPanel from './NodePropertiesPanel.vue';
import AudienceDialog from './AudienceDialog.vue';
import { NODE_TYPES, defaultDataFor } from './nodeTypes.js';
import { toVueFlow, toStorage } from './flowMappers.js';
import { layoutFlow } from './layoutFlow.js';

const EDGE_COLOR = '#6b7280';
const defaultEdgeOptions = {
  type: 'smoothstep',
  markerEnd: {
    type: MarkerType.ArrowClosed,
    color: EDGE_COLOR,
    width: 18,
    height: 18,
  },
  style: { strokeWidth: 2, stroke: EDGE_COLOR },
  labelStyle: { fill: '#e6e8eb', fontSize: 12, fontWeight: 600 },
  labelBgStyle: { fill: '#0f1115', fillOpacity: 0.92 },
  labelBgPadding: [8, 5],
  labelBgBorderRadius: 6,
};

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const store = useStore();

const inboxes = useMapGetter('inboxes/getInboxes');
const uiFlags = useMapGetter('workflows/getUIFlags');

const {
  onConnect,
  addEdges,
  addNodes,
  removeNodes,
  removeEdges,
  onNodeClick,
  onEdgeClick,
  onPaneClick,
  fitView,
} = useVueFlow();

const refitView = () =>
  nextTick(() => fitView({ padding: 0.2, duration: 300 }));

const nodes = ref([]);
const edges = ref([]);
const selected = ref(null);
const mode = ref('canvas');
const jsonBuffer = ref('');
const jsonError = ref('');
let nodeCounter = 0;

const name = ref('');
const inboxId = ref('');
const triggerType = ref('conversation_created');
const status = ref('draft');
const audienceType = ref('customer_facing');
const triggerRules = ref({});
const audienceDialogRef = ref(null);

const workflowId = computed(() => route.params.workflowId);
const isEditing = computed(() => !!workflowId.value);
const isSaving = computed(
  () => uiFlags.value.isCreating || uiFlags.value.isUpdating
);

const inboxOptions = computed(() =>
  inboxes.value.map(inbox => ({ value: inbox.id, label: inbox.name }))
);
const triggerOptions = computed(() => [
  {
    value: 'conversation_created',
    label: t('WORKFLOWS.TRIGGERS.CONVERSATION_CREATED'),
  },
  { value: 'first_message', label: t('WORKFLOWS.TRIGGERS.FIRST_MESSAGE') },
  { value: 'inactivity', label: t('WORKFLOWS.TRIGGERS.INACTIVITY') },
  { value: 'manual', label: t('WORKFLOWS.TRIGGERS.MANUAL') },
]);
const statusOptions = computed(() => [
  { value: 'draft', label: t('WORKFLOWS.STATUS.DRAFT') },
  { value: 'live', label: t('WORKFLOWS.STATUS.LIVE') },
  { value: 'archived', label: t('WORKFLOWS.STATUS.ARCHIVED') },
]);

const nextNodeId = () => {
  nodeCounter += 1;
  return `n${nodeCounter}`;
};

const loadFlow = flow => {
  const mapped = toVueFlow(flow || {});
  // Auto-arrange when the stored flow has no saved positions (e.g. pasted JSON).
  const hasPositions = (flow?.nodes || []).some(node => node.position);
  nodes.value = hasPositions
    ? mapped.nodes
    : layoutFlow(mapped.nodes, mapped.edges);
  edges.value = mapped.edges;
  nodeCounter = mapped.nodes.reduce((max, node) => {
    const numeric = Number(String(node.id).replace(/\D/g, ''));
    return Number.isFinite(numeric) && numeric > max ? numeric : max;
  }, 0);
  refitView();
};

const tidy = () => {
  nodes.value = layoutFlow(nodes.value, edges.value);
  refitView();
};

const hydrate = workflow => {
  name.value = workflow.name;
  inboxId.value = workflow.inbox_id;
  triggerType.value = workflow.trigger_type;
  status.value = workflow.status;
  audienceType.value = workflow.audience_type || 'customer_facing';
  triggerRules.value = workflow.trigger_rules || {};
  loadFlow(workflow.flow);
};

const onAudienceSave = ({ audience_type: type, trigger_rules: rules }) => {
  audienceType.value = type;
  triggerRules.value = rules;
};

onMounted(async () => {
  store.dispatch('inboxes/get');
  if (isEditing.value) {
    let workflow = store.getters['workflows/getWorkflow'](workflowId.value);
    if (!workflow) {
      await store.dispatch('workflows/get');
      workflow = store.getters['workflows/getWorkflow'](workflowId.value);
    }
    if (workflow) hydrate(workflow);
  } else {
    inboxId.value = inboxOptions.value[0]?.value ?? '';
  }
});

onConnect(connection => {
  nodeCounter += 1;
  addEdges([
    {
      ...connection,
      id: `e-${connection.source}-${connection.target}-${nodeCounter}`,
      data: { match: null },
      label: '',
    },
  ]);
});
onNodeClick(({ node }) => {
  selected.value = { kind: 'node', ref: node };
});
onEdgeClick(({ edge }) => {
  selected.value = { kind: 'edge', ref: edge };
});
onPaneClick(() => {
  selected.value = null;
});

const addNodeOfType = type => {
  addNodes([
    {
      id: nextNodeId(),
      type: 'flow',
      position: { x: 280, y: 40 + nodes.value.length * 40 },
      data: defaultDataFor(type),
    },
  ]);
};

const deleteSelected = () => {
  if (!selected.value) return;
  if (selected.value.kind === 'node') removeNodes([selected.value.ref.id]);
  else removeEdges([selected.value.ref.id]);
  selected.value = null;
};

// Mutations applied here because this component owns the Vue Flow store;
// the panel is presentational and only emits intent.
const updateField = (key, value) => {
  selected.value.ref.data[key] = value;
};
const updateButton = (key, index, prop, value) => {
  const list = (selected.value.ref.data[key] || []).map((item, i) =>
    i === index ? { ...item, [prop]: value } : item
  );
  selected.value.ref.data[key] = list;
};
const addButton = key => {
  const list = (selected.value.ref.data[key] || []).slice();
  list.push({ title: '', value: '' });
  selected.value.ref.data[key] = list;
};
const removeButton = (key, index) => {
  const list = (selected.value.ref.data[key] || []).slice();
  list.splice(index, 1);
  selected.value.ref.data[key] = list;
};
const applyFieldJson = (key, value) => {
  try {
    selected.value.ref.data[key] = JSON.parse(value);
  } catch (error) {
    // keep previous value on invalid json
  }
};
const setEdgeMatch = value => {
  const el = selected.value.ref;
  if (value === 'button') el.data.match = { type: 'button', value: '' };
  else if (value === 'condition')
    el.data.match = { type: 'condition', conditions: [] };
  else el.data.match = { type: 'fallback' };
  el.label = value === 'fallback' ? 'else' : '';
};
const setEdgeButtonValue = value => {
  selected.value.ref.data.match = { type: 'button', value };
  selected.value.ref.label = value;
};

const switchToJson = () => {
  jsonBuffer.value = JSON.stringify(
    toStorage(nodes.value, edges.value),
    null,
    2
  );
  jsonError.value = '';
  mode.value = 'json';
};

const applyJsonToCanvas = () => {
  try {
    loadFlow(JSON.parse(jsonBuffer.value));
    jsonError.value = '';
    mode.value = 'canvas';
    selected.value = null;
  } catch (error) {
    jsonError.value = t('WORKFLOWS.FORM.FLOW.INVALID');
  }
};

const toggleMode = () => {
  if (mode.value === 'canvas') switchToJson();
  else applyJsonToCanvas();
};

const buildFlow = () => {
  if (mode.value === 'json') return JSON.parse(jsonBuffer.value);
  return toStorage(nodes.value, edges.value);
};

const goBack = () => router.push({ name: 'workflows_index' });

const save = async () => {
  let flow;
  try {
    flow = buildFlow();
  } catch (error) {
    jsonError.value = t('WORKFLOWS.FORM.FLOW.INVALID');
    return;
  }
  if (!name.value || !inboxId.value) return;

  const payload = {
    name: name.value,
    inbox_id: inboxId.value,
    trigger_type: triggerType.value,
    status: status.value,
    audience_type: audienceType.value,
    trigger_rules: triggerRules.value,
    flow,
  };

  try {
    if (isEditing.value) {
      await store.dispatch('workflows/update', {
        id: Number(workflowId.value),
        ...payload,
      });
      useAlert(t('WORKFLOWS.EDIT.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('workflows/create', payload);
      useAlert(t('WORKFLOWS.ADD.API.SUCCESS_MESSAGE'));
    }
    goBack();
  } catch (error) {
    useAlert(error.message || t('WORKFLOWS.ADD.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div class="flex flex-col w-full h-full font-inter">
    <!-- Top bar -->
    <div
      class="flex items-end gap-3 px-4 py-3 border-b border-n-weak flex-wrap"
    >
      <Button
        variant="ghost"
        size="sm"
        icon="i-lucide-arrow-left"
        :label="t('WORKFLOWS.BUILDER.BACK')"
        @click="goBack"
      />
      <div class="flex flex-col gap-1 w-56">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WORKFLOWS.FORM.NAME.LABEL') }}
        </label>
        <Input
          v-model="name"
          :placeholder="t('WORKFLOWS.FORM.NAME.PLACEHOLDER')"
        />
      </div>
      <div class="flex flex-col gap-1 w-44">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WORKFLOWS.FORM.INBOX.LABEL') }}
        </label>
        <Select v-model="inboxId" :options="inboxOptions" />
      </div>
      <div class="flex flex-col gap-1 w-52">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WORKFLOWS.FORM.TRIGGER.LABEL') }}
        </label>
        <Select v-model="triggerType" :options="triggerOptions" />
      </div>
      <div class="flex flex-col gap-1 w-32">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WORKFLOWS.FORM.STATUS.LABEL') }}
        </label>
        <Select v-model="status" :options="statusOptions" />
      </div>
      <div class="flex items-center gap-2 ml-auto">
        <Button
          variant="ghost"
          size="sm"
          icon="i-lucide-users"
          :label="t('WORKFLOWS.AUDIENCE.BUTTON')"
          @click="audienceDialogRef.open()"
        />
        <Button
          v-if="mode === 'canvas'"
          variant="ghost"
          size="sm"
          icon="i-lucide-layout-dashboard"
          :label="t('WORKFLOWS.BUILDER.TIDY')"
          @click="tidy"
        />
        <Button
          variant="outline"
          size="sm"
          :icon="mode === 'canvas' ? 'i-lucide-code' : 'i-lucide-workflow'"
          :label="
            mode === 'canvas'
              ? t('WORKFLOWS.BUILDER.VIEW_JSON')
              : t('WORKFLOWS.BUILDER.VIEW_CANVAS')
          "
          @click="toggleMode"
        />
        <Button
          size="sm"
          :label="t('WORKFLOWS.FORM.SAVE')"
          :is-loading="isSaving"
          @click="save"
        />
      </div>
    </div>

    <!-- Body -->
    <div class="flex flex-1 min-h-0">
      <!-- JSON mode -->
      <div v-if="mode === 'json'" class="flex-1 p-4 flex flex-col gap-2">
        <TextArea
          v-model="jsonBuffer"
          class="flex-1 font-mono text-xs [&_textarea]:h-full"
          :message="jsonError"
          :message-type="jsonError ? 'error' : 'info'"
        />
        <p class="text-xs text-n-slate-11">
          {{ t('WORKFLOWS.BUILDER.JSON_HINT') }}
        </p>
      </div>

      <!-- Canvas mode -->
      <template v-else>
        <!-- Palette -->
        <div
          class="w-48 shrink-0 border-r border-n-weak bg-n-solid-1 p-2 overflow-y-auto flex flex-col gap-1"
        >
          <p class="px-2 py-1 text-xs font-semibold text-n-slate-11 uppercase">
            {{ t('WORKFLOWS.BUILDER.PALETTE') }}
          </p>
          <button
            v-for="nodeType in NODE_TYPES"
            :key="nodeType.type"
            class="flex items-center gap-2 px-2 py-1.5 rounded-md text-left hover:bg-n-alpha-2 text-sm text-n-slate-12"
            @click="addNodeOfType(nodeType.type)"
          >
            <span class="text-base" :class="[nodeType.icon, nodeType.color]" />
            {{ nodeType.label }}
          </button>
        </div>

        <!-- Flow canvas -->
        <div class="flex-1 relative min-w-0">
          <VueFlow
            v-model:nodes="nodes"
            v-model:edges="edges"
            :default-edge-options="defaultEdgeOptions"
            :min-zoom="0.2"
            :max-zoom="1.5"
            fit-view-on-init
            class="bg-n-background"
          >
            <template #node-flow="nodeProps">
              <FlowNode :data="nodeProps.data" :selected="nodeProps.selected" />
            </template>
            <Background :gap="20" :size="1" pattern-color="#3b3f45" />
            <Controls position="bottom-left" />
            <MiniMap pannable class="!bg-n-solid-1" />
          </VueFlow>
        </div>

        <!-- Properties -->
        <NodePropertiesPanel
          v-if="selected"
          :selected="selected"
          @delete="deleteSelected"
          @update-field="updateField"
          @update-button="updateButton"
          @add-button="addButton"
          @remove-button="removeButton"
          @apply-json="applyFieldJson"
          @set-edge-match="setEdgeMatch"
          @set-edge-button-value="setEdgeButtonValue"
        />
      </template>
    </div>

    <AudienceDialog
      ref="audienceDialogRef"
      :trigger-rules="triggerRules"
      :audience-type="audienceType"
      @save="onAudienceSave"
    />
  </div>
</template>
