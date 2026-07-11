class Workflows::TriggerService
  pattr_initialize [:conversation!, { trigger_type: :conversation_created }]

  def perform
    return unless conversation.account.workflows_enabled?

    definition = conversation.inbox.workflow_definitions
                             .live_for_inbox(conversation.inbox_id)
                             .where(trigger_type: trigger_type)
                             .first
    return if definition.blank?

    interrupt_active_execution
    execution = create_execution(definition)
    Workflows::RunnerService.new(execution: execution).perform
    execution
  end

  private

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
