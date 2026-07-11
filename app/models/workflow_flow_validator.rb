class WorkflowFlowValidator < ActiveModel::EachValidator
  MAX_NODES = 100
  MAX_BYTESIZE = 200.kilobytes

  def validate_each(record, attribute, value)
    return if value.blank?

    nodes = value['nodes'] || value[:nodes]
    record.errors.add(attribute, I18n.t('errors.workflows.flow_nodes_missing')) and return unless nodes.is_a?(Array)

    record.errors.add(attribute, I18n.t('errors.workflows.flow_too_many_nodes', max: MAX_NODES)) if nodes.length > MAX_NODES
    record.errors.add(attribute, I18n.t('errors.workflows.flow_too_large')) if value.to_json.bytesize > MAX_BYTESIZE
  end
end
