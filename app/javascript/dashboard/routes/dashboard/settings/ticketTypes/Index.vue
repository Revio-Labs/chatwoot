<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { BaseTable } from 'dashboard/components-next/table';
import TicketTypeDialog from './TicketTypeDialog.vue';

const { t } = useI18n();
const store = useStore();

const records = useMapGetter('ticketTypes/getTicketTypes');
const uiFlags = useMapGetter('ticketTypes/getUIFlags');

const dialogRef = ref(null);
const selected = ref(null);

const isLoading = computed(() => uiFlags.value.isFetching);
const isEmpty = computed(() => !isLoading.value && records.value.length === 0);

const headers = computed(() => [
  t('TICKET_TYPES.LIST.HEADERS.NAME'),
  t('TICKET_TYPES.LIST.HEADERS.CATEGORY'),
  t('TICKET_TYPES.LIST.HEADERS.FIELDS'),
  t('TICKET_TYPES.LIST.HEADERS.STATUS'),
  t('TICKET_TYPES.LIST.HEADERS.ACTIONS'),
]);

onMounted(() => {
  store.dispatch('ticketTypes/get');
});

const openCreate = () => {
  selected.value = null;
  dialogRef.value.open();
};

const openEdit = ticketType => {
  selected.value = ticketType;
  dialogRef.value.open();
};

const deleteTicketType = async id => {
  try {
    await store.dispatch('ticketTypes/delete', id);
    useAlert(t('TICKET_TYPES.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('TICKET_TYPES.DELETE.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="t('TICKET_TYPES.LIST.LOADING')"
    :no-records-found="isEmpty"
    :no-records-message="t('TICKET_TYPES.LIST.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('TICKET_TYPES.HEADER')"
        :description="t('TICKET_TYPES.DESCRIPTION')"
      >
        <template #actions>
          <Button
            :label="t('TICKET_TYPES.ADD.TITLE')"
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
          <tr v-for="ticketType in items" :key="ticketType.id">
            <td class="py-2 px-3">{{ ticketType.name }}</td>
            <td class="py-2 px-3 capitalize">{{ ticketType.category }}</td>
            <td class="py-2 px-3">
              {{ (ticketType.field_schema || []).length }}
            </td>
            <td class="py-2 px-3 capitalize">{{ ticketType.status }}</td>
            <td class="py-2 px-3">
              <div class="flex gap-2">
                <Button
                  variant="ghost"
                  size="sm"
                  icon="i-lucide-pencil"
                  @click="openEdit(ticketType)"
                />
                <Button
                  variant="ghost"
                  color="ruby"
                  size="sm"
                  icon="i-lucide-trash-2"
                  @click="deleteTicketType(ticketType.id)"
                />
              </div>
            </td>
          </tr>
        </template>
      </BaseTable>
    </template>
    <TicketTypeDialog
      ref="dialogRef"
      :ticket-type="selected"
      @saved="store.dispatch('ticketTypes/get')"
    />
  </SettingsLayout>
</template>
