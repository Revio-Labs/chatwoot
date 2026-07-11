class WorkflowListener < BaseListener
  def conversation_created(event)
    conversation = event.data[:conversation]
    return if conversation.blank? || !conversation.account.workflows_enabled?
    return unless conversation.inbox.workflow_definitions.live.exists?(trigger_type: :conversation_created)

    Workflows::AdvanceJob.perform_later(conversation.id)
  end

  def message_created(event)
    message = event.data[:message]
    return if message.blank? || !message.incoming?
    return if message.activity?

    enqueue_advance(message)
  end

  # Button taps and form submissions PATCH submitted_values onto the original
  # outgoing bot message (widget messages#update), arriving as message.updated.
  def message_updated(event)
    message = event.data[:message]
    return if message.blank? || !message.outgoing?
    return if message.content_attributes['submitted_values'].blank?

    enqueue_advance(message)
  end

  private

  def enqueue_advance(message)
    return unless message.account.workflows_enabled?
    return unless message.conversation.workflow_executions.active.exists?

    Workflows::AdvanceJob.perform_later(message.conversation_id, message.id)
  end
end
