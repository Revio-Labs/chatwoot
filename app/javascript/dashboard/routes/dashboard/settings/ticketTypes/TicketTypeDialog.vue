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
  ticketType: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['saved']);

const { t } = useI18n();
const store = useStore();
const uiFlags = useMapGetter('ticketTypes/getUIFlags');

const dialogRef = ref(null);
const name = ref('');
const category = ref('customer');
const fieldsJson = ref('[]');
const jsonError = ref('');

const isEditing = computed(() => !!props.ticketType);
const isSaving = computed(
  () => uiFlags.value.isCreating || uiFlags.value.isUpdating
);

const categoryOptions = computed(() => [
  { value: 'customer', label: t('TICKET_TYPES.CATEGORY.CUSTOMER') },
  { value: 'back_office', label: t('TICKET_TYPES.CATEGORY.BACK_OFFICE') },
  { value: 'tracker', label: t('TICKET_TYPES.CATEGORY.TRACKER') },
]);

const resetForm = () => {
  if (props.ticketType) {
    name.value = props.ticketType.name;
    category.value = props.ticketType.category;
    fieldsJson.value = JSON.stringify(
      props.ticketType.field_schema ?? [],
      null,
      2
    );
  } else {
    name.value = '';
    category.value = 'customer';
    fieldsJson.value = '[]';
  }
  jsonError.value = '';
};

watch(() => props.ticketType, resetForm, { immediate: true });

const onConfirm = async () => {
  let fieldSchema;
  try {
    fieldSchema = JSON.parse(fieldsJson.value);
  } catch (error) {
    jsonError.value = t('TICKET_TYPES.FORM.FIELDS.INVALID');
    return;
  }
  if (!name.value) return;

  const payload = {
    name: name.value,
    category: category.value,
    field_schema: fieldSchema,
  };

  try {
    if (isEditing.value) {
      await store.dispatch('ticketTypes/update', {
        id: props.ticketType.id,
        ...payload,
      });
      useAlert(t('TICKET_TYPES.EDIT.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('ticketTypes/create', payload);
      useAlert(t('TICKET_TYPES.ADD.API.SUCCESS_MESSAGE'));
    }
    emit('saved');
    dialogRef.value.close();
  } catch (error) {
    useAlert(error.message || t('TICKET_TYPES.ADD.API.ERROR_MESSAGE'));
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
    :title="
      isEditing ? t('TICKET_TYPES.EDIT.TITLE') : t('TICKET_TYPES.ADD.TITLE')
    "
    :confirm-button-label="t('TICKET_TYPES.FORM.SAVE')"
    :is-loading="isSaving"
    :disable-confirm-button="isSaving"
    width="xl"
    overflow-y-auto
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <Input
        v-model="name"
        :label="t('TICKET_TYPES.FORM.NAME.LABEL')"
        :placeholder="t('TICKET_TYPES.FORM.NAME.PLACEHOLDER')"
      />
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('TICKET_TYPES.FORM.CATEGORY.LABEL') }}
        </label>
        <Select v-model="category" :options="categoryOptions" />
      </div>
      <TextArea
        v-model="fieldsJson"
        :label="t('TICKET_TYPES.FORM.FIELDS.LABEL')"
        :message="jsonError"
        :message-type="jsonError ? 'error' : 'info'"
        class="font-mono text-xs [&_textarea]:min-h-48"
      />
    </div>
  </Dialog>
</template>
