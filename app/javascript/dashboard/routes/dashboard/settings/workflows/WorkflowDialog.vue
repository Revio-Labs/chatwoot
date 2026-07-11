<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const props = defineProps({
  workflow: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['saved']);

const { t } = useI18n();
const store = useStore();
const inboxes = useMapGetter('inboxes/getInboxes');
const uiFlags = useMapGetter('workflows/getUIFlags');

const dialogRef = ref(null);
const name = ref('');
const inboxId = ref('');
const triggerType = ref('conversation_created');
const status = ref('draft');
const flowJson = ref('{\n  "nodes": [],\n  "edges": []\n}');
const jsonError = ref('');

const isEditing = computed(() => !!props.workflow);
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

const resetForm = () => {
  if (props.workflow) {
    name.value = props.workflow.name;
    inboxId.value = props.workflow.inbox_id;
    triggerType.value = props.workflow.trigger_type;
    status.value = props.workflow.status;
    flowJson.value = JSON.stringify(props.workflow.flow ?? {}, null, 2);
  } else {
    name.value = '';
    inboxId.value = inboxOptions.value[0]?.value ?? '';
    triggerType.value = 'conversation_created';
    status.value = 'draft';
    flowJson.value = '{\n  "nodes": [],\n  "edges": []\n}';
  }
  jsonError.value = '';
};

watch(() => props.workflow, resetForm, { immediate: true });

const parseFlow = () => {
  try {
    const parsed = JSON.parse(flowJson.value);
    jsonError.value = '';
    return parsed;
  } catch (error) {
    jsonError.value = t('WORKFLOWS.FORM.FLOW.INVALID');
    return null;
  }
};

const onConfirm = async () => {
  const flow = parseFlow();
  if (flow === null) return;
  if (!name.value || !inboxId.value) return;

  const payload = {
    name: name.value,
    inbox_id: inboxId.value,
    trigger_type: triggerType.value,
    status: status.value,
    flow,
  };

  try {
    if (isEditing.value) {
      await store.dispatch('workflows/update', {
        id: props.workflow.id,
        ...payload,
      });
      useAlert(t('WORKFLOWS.EDIT.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('workflows/create', payload);
      useAlert(t('WORKFLOWS.ADD.API.SUCCESS_MESSAGE'));
    }
    emit('saved');
    dialogRef.value.close();
  } catch (error) {
    useAlert(error.message || t('WORKFLOWS.ADD.API.ERROR_MESSAGE'));
  }
};

defineExpose({
  open: () => {
    resetForm();
    dialogRef.value.open();
  },
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="isEditing ? t('WORKFLOWS.EDIT.TITLE') : t('WORKFLOWS.ADD.TITLE')"
    :confirm-button-label="t('WORKFLOWS.FORM.SAVE')"
    :is-loading="isSaving"
    :disable-confirm-button="isSaving"
    width="2xl"
    overflow-y-auto
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="name"
        :label="t('WORKFLOWS.FORM.NAME.LABEL')"
        :placeholder="t('WORKFLOWS.FORM.NAME.PLACEHOLDER')"
      />
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('WORKFLOWS.FORM.INBOX.LABEL') }}
        </label>
        <Select v-model="inboxId" :options="inboxOptions" />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('WORKFLOWS.FORM.TRIGGER.LABEL') }}
        </label>
        <Select v-model="triggerType" :options="triggerOptions" />
      </div>
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('WORKFLOWS.FORM.STATUS.LABEL') }}
        </label>
        <Select v-model="status" :options="statusOptions" />
      </div>
      <TextArea
        v-model="flowJson"
        :label="t('WORKFLOWS.FORM.FLOW.LABEL')"
        :message="jsonError"
        :message-type="jsonError ? 'error' : 'info'"
        class="font-mono text-xs [&_textarea]:min-h-64"
      />
    </div>
  </Dialog>
</template>
