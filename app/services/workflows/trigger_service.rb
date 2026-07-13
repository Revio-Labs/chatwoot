class Workflows::TriggerService
  pattr_initialize [:conversation!, { trigger_type: :conversation_created }]

  # Among the live customer-facing workflows for this inbox + trigger, in
  # priority order, start the FIRST one whose audience (trigger_rules) matches
  # this conversation — Intercom's "only the top matching workflow fires".
  def perform
    return unless conversation.account.workflows_enabled?

    definition = matching_definition
    return if definition.blank?

    interrupt_active_execution
    execution = create_execution(definition)
    Workflows::RunnerService.new(execution: execution).perform
    execution
  end

  private

  def matching_definition
    matcher = Workflows::AudienceMatcher.new(conversation: conversation)
    conversation.inbox.workflow_definitions
                .live_for_inbox(conversation.inbox_id)
                .customer_facing
                .where(trigger_type: trigger_type)
                .detect { |definition| matcher.matches?(definition) }
  end

  def interrupt_active_execution
    conversation.workflow_executions.active.find_each(&:interrupted!)
  end

  def create_execution(definition)
    conversation.workflow_executions.create!(
      account_id: conversation.account_id,
      workflow_definition: definition,
      flow_snapshot: definition.flow,
      last_activity_at: Time.current
    )
  end
end
