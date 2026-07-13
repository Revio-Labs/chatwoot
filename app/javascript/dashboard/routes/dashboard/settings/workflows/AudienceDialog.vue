<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  triggerRules: {
    type: Object,
    default: () => ({}),
  },
  audienceType: {
    type: String,
    default: 'customer_facing',
  },
});

const emit = defineEmits(['save']);

const { t } = useI18n();

const dialogRef = ref(null);
const contactType = ref('any');
const localAudienceType = ref('customer_facing');
const conditions = ref([]);

const contactTypeOptions = [
  { value: 'any', label: t('WORKFLOWS.AUDIENCE.CONTACT_TYPE.ANY') },
  {
    value: 'identified',
    label: t('WORKFLOWS.AUDIENCE.CONTACT_TYPE.IDENTIFIED'),
  },
  { value: 'visitor', label: t('WORKFLOWS.AUDIENCE.CONTACT_TYPE.VISITOR') },
];

const audienceTypeOptions = [
  {
    value: 'customer_facing',
    label: t('WORKFLOWS.AUDIENCE.TYPE.CUSTOMER_FACING'),
  },
  { value: 'background', label: t('WORKFLOWS.AUDIENCE.TYPE.BACKGROUND') },
];

const scopeOptions = [
  { value: 'contact', label: t('WORKFLOWS.AUDIENCE.SCOPE.CONTACT') },
  { value: 'conversation', label: t('WORKFLOWS.AUDIENCE.SCOPE.CONVERSATION') },
];

const operatorOptions = [
  { value: 'equal_to', label: t('WORKFLOWS.AUDIENCE.OPERATOR.EQUAL') },
  { value: 'not_equal_to', label: t('WORKFLOWS.AUDIENCE.OPERATOR.NOT_EQUAL') },
  { value: 'contains', label: t('WORKFLOWS.AUDIENCE.OPERATOR.CONTAINS') },
];

const reset = () => {
  contactType.value = props.triggerRules?.contact_type || 'any';
  localAudienceType.value = props.audienceType || 'customer_facing';
  conditions.value = (props.triggerRules?.conditions || []).map(condition => ({
    scope: condition.scope || 'contact',
    attribute_key: condition.attribute_key || '',
    filter_operator: condition.filter_operator || 'equal_to',
    value: Array.isArray(condition.values) ? condition.values[0] : '',
  }));
};

watch(() => [props.triggerRules, props.audienceType], reset, {
  immediate: true,
});

const addCondition = () => {
  conditions.value.push({
    scope: 'contact',
    attribute_key: '',
    filter_operator: 'equal_to',
    value: '',
  });
};

const removeCondition = index => {
  conditions.value.splice(index, 1);
};

const onConfirm = () => {
  const cleaned = conditions.value
    .filter(condition => condition.attribute_key)
    .map(condition => ({
      scope: condition.scope,
      attribute_key: condition.attribute_key,
      filter_operator: condition.filter_operator,
      values: [condition.value],
    }));

  emit('save', {
    audience_type: localAudienceType.value,
    trigger_rules: { contact_type: contactType.value, conditions: cleaned },
  });
  dialogRef.value.close();
};

defineExpose({
  open: () => {
    reset();
    dialogRef.value.open();
  },
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('WORKFLOWS.AUDIENCE.TITLE')"
    :description="t('WORKFLOWS.AUDIENCE.DESCRIPTION')"
    :confirm-button-label="t('WORKFLOWS.FORM.SAVE')"
    width="2xl"
    overflow-y-auto
    @confirm="onConfirm"
  >
    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('WORKFLOWS.AUDIENCE.TYPE.LABEL') }}
        </label>
        <Select v-model="localAudienceType" :options="audienceTypeOptions" />
      </div>

      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('WORKFLOWS.AUDIENCE.CONTACT_TYPE.LABEL') }}
        </label>
        <Select v-model="contactType" :options="contactTypeOptions" />
      </div>

      <div class="flex flex-col gap-2">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('WORKFLOWS.AUDIENCE.CONDITIONS') }}
        </label>
        <div
          v-for="(condition, index) in conditions"
          :key="index"
          class="flex items-center gap-2"
        >
          <Select
            v-model="condition.scope"
            :options="scopeOptions"
            class="w-32 shrink-0"
          />
          <Input
            v-model="condition.attribute_key"
            :placeholder="t('WORKFLOWS.AUDIENCE.ATTRIBUTE_PLACEHOLDER')"
          />
          <Select
            v-model="condition.filter_operator"
            :options="operatorOptions"
            class="w-28 shrink-0"
          />
          <Input v-model="condition.value" placeholder="value" />
          <Button
            variant="ghost"
            color="ruby"
            size="sm"
            icon="i-lucide-x"
            @click="removeCondition(index)"
          />
        </div>
        <Button
          variant="link"
          size="sm"
          icon="i-lucide-plus"
          :label="t('WORKFLOWS.AUDIENCE.ADD_CONDITION')"
          @click="addCondition"
        />
      </div>
    </div>
  </Dialog>
</template>
