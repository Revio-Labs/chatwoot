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
  if (d.team_id) return `Team #${d.team_id}`;
  if (d.agent_id) return `Agent #${d.agent_id}`;
  if (d.seconds) return `Wait ${d.seconds}s`;
  if (d.workflow_definition_id)
    return `Go to workflow #${d.workflow_definition_id}`;
  if (d.priority) return `Priority: ${d.priority}`;
  return '';
});

const buttonCount = computed(() =>
  Array.isArray(props.data.items) ? props.data.items.length : 0
);
</script>

<template>
  <div
    class="w-[264px] rounded-xl border bg-n-solid-2 transition-shadow"
    :class="
      selected
        ? 'border-n-brand ring-2 ring-n-brand/40 shadow-lg'
        : 'border-n-weak shadow-sm hover:shadow-md'
    "
  >
    <Handle
      type="target"
      :position="Position.Left"
      class="!w-2.5 !h-2.5 !bg-n-slate-8 !border-2 !border-n-solid-2"
    />

    <!-- Header -->
    <div class="flex items-center gap-2.5 px-3 py-2.5">
      <span
        class="grid place-items-center w-7 h-7 rounded-lg bg-n-alpha-2 shrink-0"
      >
        <span
          class="text-base"
          :class="[def.icon, def.color || 'text-n-slate-11']"
        />
      </span>
      <span class="text-sm font-semibold text-n-slate-12 truncate">
        {{ def.label || data.type }}
      </span>
    </div>

    <!-- Body -->
    <div
      v-if="summary || buttonCount"
      class="px-3 pb-2.5 -mt-0.5 flex flex-col gap-1.5"
    >
      <p
        v-if="summary"
        class="text-xs leading-relaxed text-n-slate-11 line-clamp-2 break-words"
      >
        {{ summary }}
      </p>
      <div v-if="buttonCount" class="flex flex-wrap gap-1">
        <span
          v-for="(item, index) in data.items.slice(0, 4)"
          :key="index"
          class="px-1.5 py-0.5 rounded-md bg-n-alpha-2 text-[10px] text-n-slate-11 truncate max-w-[110px]"
        >
          {{ item.title || item.label || item.value }}
        </span>
        <span
          v-if="buttonCount > 4"
          class="px-1.5 py-0.5 rounded-md text-[10px] text-n-slate-10"
        >
          +{{ buttonCount - 4 }}
        </span>
      </div>
    </div>

    <Handle
      type="source"
      :position="Position.Right"
      class="!w-2.5 !h-2.5 !bg-n-slate-8 !border-2 !border-n-solid-2"
    />
  </div>
</template>
