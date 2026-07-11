<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Select from 'dashboard/components-next/select/Select.vue';
import { BaseTable } from 'dashboard/components-next/table';

const { t } = useI18n();
const store = useStore();

const records = useMapGetter('tickets/getTickets');
const uiFlags = useMapGetter('tickets/getUIFlags');
const ticketTypes = useMapGetter('ticketTypes/getTicketTypes');

const typeFilter = ref('');
const stateFilter = ref('');

const isLoading = computed(() => uiFlags.value.isFetching);

const typeOptions = computed(() => [
  { value: '', label: t('TICKETS.FILTERS.ALL_TYPES') },
  ...ticketTypes.value.map(type => ({
    value: String(type.id),
    label: type.name,
  })),
]);

const stateOptions = computed(() => [
  { value: '', label: t('TICKETS.FILTERS.ALL_STATES') },
  { value: 'submitted', label: t('TICKETS.STATE.SUBMITTED') },
  { value: 'in_progress', label: t('TICKETS.STATE.IN_PROGRESS') },
  { value: 'waiting', label: t('TICKETS.STATE.WAITING') },
  { value: 'resolved', label: t('TICKETS.STATE.RESOLVED') },
]);

const headers = computed(() => [
  t('TICKETS.LIST.HEADERS.ID'),
  t('TICKETS.LIST.HEADERS.TITLE'),
  t('TICKETS.LIST.HEADERS.TYPE'),
  t('TICKETS.LIST.HEADERS.STATE'),
  t('TICKETS.LIST.HEADERS.CONTACT'),
  t('TICKETS.LIST.HEADERS.CREATED'),
]);

const fetchTickets = () => {
  const params = {};
  if (typeFilter.value) params.ticket_type_id = typeFilter.value;
  if (stateFilter.value) params.state = stateFilter.value;
  store.dispatch('tickets/get', params);
};

const formatDate = value =>
  value ? new Date(value).toLocaleDateString() : '—';

onMounted(() => {
  store.dispatch('ticketTypes/get');
  fetchTickets();
});

watch([typeFilter, stateFilter], fetchTickets);
</script>

<template>
  <div class="flex flex-col w-full h-full gap-4 p-6 overflow-auto">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-medium text-n-slate-12">
          {{ t('TICKETS.HEADER') }}
        </h1>
        <p class="text-sm text-n-slate-11">{{ t('TICKETS.DESCRIPTION') }}</p>
      </div>
      <div class="flex gap-3 w-96">
        <Select v-model="typeFilter" :options="typeOptions" />
        <Select v-model="stateFilter" :options="stateOptions" />
      </div>
    </div>
    <BaseTable
      :headers="headers"
      :items="records"
      :loading="isLoading"
      :no-data-message="t('TICKETS.LIST.EMPTY')"
    >
      <template #row="{ items }">
        <tr v-for="ticket in items" :key="ticket.id">
          <td class="py-2 px-3">{{ `#${ticket.display_id}` }}</td>
          <td class="py-2 px-3">{{ ticket.title }}</td>
          <td class="py-2 px-3">{{ ticket.ticket_type_name }}</td>
          <td class="py-2 px-3 capitalize">
            {{ ticket.state?.replace('_', ' ') }}
          </td>
          <td class="py-2 px-3">{{ ticket.contact_name || '—' }}</td>
          <td class="py-2 px-3">{{ formatDate(ticket.created_at) }}</td>
        </tr>
      </template>
    </BaseTable>
  </div>
</template>
