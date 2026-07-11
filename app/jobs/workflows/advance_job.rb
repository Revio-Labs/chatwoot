# Serializes all workflow advancement per conversation behind a Redis mutex so
# rapid customer replies cannot corrupt execution state. The partial unique
# index on workflow_executions is the DB backstop.
class Workflows::AdvanceJob < MutexApplicationJob
  queue_as :high

  retry_on_lock_conflict wait: 2.seconds, attempts: 5

  LOCK_KEY = 'WORKFLOW_RUNNER::%<account_id>d::%<conversation_id>d'.freeze
  LOCK_TIMEOUT = 15.seconds

  def perform(conversation_id, message_id = nil)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    key = format(LOCK_KEY, account_id: conversation.account_id, conversation_id: conversation.id)
    with_lock(key, LOCK_TIMEOUT) do
      advance(conversation, message_id)
    end
  end

  private

  def advance(conversation, message_id)
    execution = conversation.workflow_executions.active.first

    if execution.present?
      message = message_id.present? ? conversation.messages.find_by(id: message_id) : nil
      Workflows::RunnerService.new(execution: execution).perform(message: message)
    elsif message_id.blank?
      Workflows::TriggerService.new(conversation: conversation).perform
    end
  end
end
