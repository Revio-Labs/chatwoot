<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { BaseTable } from 'dashboard/components-next/table';
import WorkflowDialog from './WorkflowDialog.vue';

const { t } = useI18n();
const store = useStore();

const records = useMapGetter('workflows/getWorkflows');
const uiFlags = useMapGetter('workflows/getUIFlags');
const inboxes = useMapGetter('inboxes/getInboxes');

const dialogRef = ref(null);
const selectedWorkflow = ref(null);

const isLoading = computed(() => uiFlags.value.isFetching);
const isEmpty = computed(() => !isLoading.value && records.value.length === 0);

const headers = computed(() => [
  t('WORKFLOWS.LIST.HEADERS.NAME'),
  t('WORKFLOWS.LIST.HEADERS.INBOX'),
  t('WORKFLOWS.LIST.HEADERS.TRIGGER'),
  t('WORKFLOWS.LIST.HEADERS.STATUS'),
  t('WORKFLOWS.LIST.HEADERS.ACTIONS'),
]);

const inboxName = id =>
  inboxes.value.find(inbox => inbox.id === id)?.name ?? '—';

onMounted(() => {
  store.dispatch('workflows/get');
  store.dispatch('inboxes/get');
});

const openCreate = () => {
  selectedWorkflow.value = null;
  dialogRef.value.open();
};

const openEdit = workflow => {
  selectedWorkflow.value = workflow;
  dialogRef.value.open();
};

const deleteWorkflow = async id => {
  try {
    await store.dispatch('workflows/delete', id);
    useAlert(t('WORKFLOWS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('WORKFLOWS.DELETE.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="t('WORKFLOWS.LIST.LOADING')"
    :no-records-found="isEmpty"
    :no-records-message="t('WORKFLOWS.LIST.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('WORKFLOWS.HEADER')"
        :description="t('WORKFLOWS.DESCRIPTION')"
      >
        <template #actions>
          <Button
            :label="t('WORKFLOWS.ADD.TITLE')"
            icon="i-lucide-plus"
            size="sm"
            @click="openCreate"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <BaseTable :headers="headers" :items="records">
        <template #row="{ items }">
          <tr v-for="workflow in items" :key="workflow.id">
            <td class="py-2 px-3">{{ workflow.name }}</td>
            <td class="py-2 px-3">{{ inboxName(workflow.inbox_id) }}</td>
            <td class="py-2 px-3">{{ workflow.trigger_type }}</td>
            <td class="py-2 px-3">
              <span class="capitalize">{{ workflow.status }}</span>
            </td>
            <td class="py-2 px-3">
              <div class="flex gap-2">
                <Button
                  variant="ghost"
                  size="sm"
                  icon="i-lucide-pencil"
                  @click="openEdit(workflow)"
                />
                <Button
                  variant="ghost"
                  color="ruby"
                  size="sm"
                  icon="i-lucide-trash-2"
                  @click="deleteWorkflow(workflow.id)"
                />
              </div>
            </td>
          </tr>
        </template>
      </BaseTable>
    </template>
    <WorkflowDialog
      ref="dialogRef"
      :workflow="selectedWorkflow"
      @saved="store.dispatch('workflows/get')"
    />
  </SettingsLayout>
</template>
