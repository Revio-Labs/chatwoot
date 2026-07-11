# Resumes workflow executions whose delay nodes have elapsed. Runs every
# minute via sidekiq-cron; survives Redis loss because wake_at lives in Postgres.
class Workflows::WakeSweepJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    WorkflowExecution.active.where('wake_at <= ?', Time.current).find_each do |execution|
      execution.update!(wake_at: nil)
      Workflows::AdvanceJob.perform_later(execution.conversation_id)
    end
  end
end
