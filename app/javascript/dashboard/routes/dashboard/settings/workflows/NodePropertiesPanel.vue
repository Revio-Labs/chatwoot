<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { nodeTypeFor } from './nodeTypes.js';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  // The selected element: { kind: 'node'|'edge', ref: <vueflow node or edge> }
  selected: {
    type: Object,
    required: true,
  },
});

// Mutations are applied by the parent (which owns the Vue Flow store).
const emit = defineEmits([
  'delete',
  'updateField',
  'updateButton',
  'addButton',
  'removeButton',
  'applyJson',
  'setEdgeMatch',
  'setEdgeButtonValue',
]);

const { t } = useI18n();

const data = computed(() => props.selected.ref.data);
const nodeDef = computed(() =>
  props.selected.kind === 'node' ? nodeTypeFor(data.value.type) : null
);

const buttonsFor = key =>
  Array.isArray(data.value[key]) ? data.value[key] : [];
const jsonString = key => JSON.stringify(data.value[key] ?? [], null, 2);

const edgeMatchType = computed(() => data.value.match?.type || 'fallback');

const matchOptions = [
  { value: 'button', label: t('WORKFLOWS.BUILDER.EDGE.BUTTON') },
  { value: 'condition', label: t('WORKFLOWS.BUILDER.EDGE.CONDITION') },
  { value: 'fallback', label: t('WORKFLOWS.BUILDER.EDGE.FALLBACK') },
];
</script>

<template>
  <div
    class="w-72 shrink-0 border-l border-n-weak bg-n-solid-1 p-4 overflow-y-auto flex flex-col gap-4"
  >
    <!-- NODE -->
    <template v-if="selected.kind === 'node'">
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-semibold text-n-slate-12">
          {{ nodeDef?.label || data.type }}
        </h3>
        <Button
          variant="ghost"
          color="ruby"
          size="sm"
          icon="i-lucide-trash-2"
          @click="emit('delete')"
        />
      </div>
      <div
        v-for="field in nodeDef?.fields || []"
        :key="field.key"
        class="flex flex-col gap-1"
      >
        <label class="text-xs font-medium text-n-slate-11">
          {{ field.label }}
        </label>

        <TextArea
          v-if="field.type === 'textarea'"
          :model-value="data[field.key]"
          @update:model-value="emit('updateField', field.key, $event)"
        />
        <Select
          v-else-if="field.type === 'select'"
          :model-value="data[field.key]"
          :options="field.options"
          @update:model-value="emit('updateField', field.key, $event)"
        />
        <Input
          v-else-if="field.type === 'number'"
          type="number"
          :model-value="data[field.key]"
          @update:model-value="emit('updateField', field.key, $event)"
        />
        <!-- Buttons repeater -->
        <div v-else-if="field.type === 'buttons'" class="flex flex-col gap-2">
          <div
            v-for="(btn, index) in buttonsFor(field.key)"
            :key="index"
            class="flex items-center gap-1"
          >
            <Input
              :model-value="btn.title"
              placeholder="Label"
              @update:model-value="
                emit('updateButton', field.key, index, 'title', $event)
              "
            />
            <Input
              :model-value="btn.value"
              placeholder="value"
              @update:model-value="
                emit('updateButton', field.key, index, 'value', $event)
              "
            />
            <Button
              variant="ghost"
              color="ruby"
              size="sm"
              icon="i-lucide-x"
              @click="emit('removeButton', field.key, index)"
            />
          </div>
          <Button
            variant="link"
            size="sm"
            icon="i-lucide-plus"
            :label="t('WORKFLOWS.BUILDER.ADD_BUTTON')"
            @click="emit('addButton', field.key)"
          />
        </div>
        <!-- JSON field -->
        <TextArea
          v-else-if="field.type === 'json'"
          :model-value="jsonString(field.key)"
          class="font-mono text-xs"
          @update:model-value="emit('applyJson', field.key, $event)"
        />
        <Input
          v-else
          :model-value="data[field.key]"
          @update:model-value="emit('updateField', field.key, $event)"
        />
      </div>
      <p v-if="!(nodeDef?.fields || []).length" class="text-xs text-n-slate-11">
        {{ t('WORKFLOWS.BUILDER.NO_CONFIG') }}
      </p>
    </template>

    <!-- EDGE -->
    <template v-else>
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-semibold text-n-slate-12">
          {{ t('WORKFLOWS.BUILDER.EDGE.TITLE') }}
        </h3>
        <Button
          variant="ghost"
          color="ruby"
          size="sm"
          icon="i-lucide-trash-2"
          @click="emit('delete')"
        />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WORKFLOWS.BUILDER.EDGE.MATCH') }}
        </label>
        <Select
          :model-value="edgeMatchType"
          :options="matchOptions"
          @update:model-value="emit('setEdgeMatch', $event)"
        />
      </div>
      <div v-if="edgeMatchType === 'button'" class="flex flex-col gap-1">
        <label class="text-xs font-medium text-n-slate-11">
          {{ t('WORKFLOWS.BUILDER.EDGE.BUTTON_VALUE') }}
        </label>
        <Input
          :model-value="data.match?.value"
          @update:model-value="emit('setEdgeButtonValue', $event)"
        />
      </div>
    </template>
  </div>
</template>
