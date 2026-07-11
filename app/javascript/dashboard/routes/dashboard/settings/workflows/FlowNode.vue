<script setup>
import { computed } from 'vue';
import { Handle, Position } from '@vue-flow/core';
import { nodeTypeFor } from './nodeTypes.js';

const props = defineProps({
  data: {
    type: Object,
    default: () => ({}),
  },
  selected: {
    type: Boolean,
    default: false,
  },
});

const def = computed(() => nodeTypeFor(props.data.type) || {});

const summary = computed(() => {
  const d = props.data;
  if (d.content) return d.content;
  if (d.key) return `${d.scope || 'contact'}.${d.key} = ${d.value ?? ''}`;
  if (d.label) return d.label;
  if (d.team_id) return `Team ${d.team_id}`;
  if (d.seconds) return `${d.seconds}s`;
  if (d.workflow_definition_id) return `→ #${d.workflow_definition_id}`;
  return def.value.label || d.type;
});
</script>

<template>
  <div
    class="min-w-40 max-w-56 rounded-lg border bg-n-solid-2 shadow-sm"
    :class="selected ? 'border-n-brand ring-1 ring-n-brand' : 'border-n-weak'"
  >
    <Handle type="target" :position="Position.Top" />
    <div class="flex items-center gap-2 px-3 py-2 border-b border-n-weak">
      <span
        class="text-base"
        :class="[def.icon, def.color || 'text-n-slate-11']"
      />
      <span class="text-sm font-medium text-n-slate-12 truncate">
        {{ def.label || data.type }}
      </span>
    </div>
    <p class="px-3 py-2 text-xs text-n-slate-11 line-clamp-3 break-words">
      {{ summary }}
    </p>
    <Handle type="source" :position="Position.Bottom" />
  </div>
</template>
