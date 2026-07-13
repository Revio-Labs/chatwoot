require 'rails_helper'

RSpec.describe Workflows::WakeSweepJob do
  let(:account) { create(:account) }

  it 'resumes executions whose wake_at has elapsed and clears the timer' do
    due = create(:workflow_execution, account: account, status: :active, wake_at: 1.minute.ago)
    create(:workflow_execution, account: account, status: :active, wake_at: 1.hour.from_now)

    expect(Workflows::AdvanceJob).to receive(:perform_later).with(due.conversation_id).once
    described_class.perform_now
    expect(due.reload.wake_at).to be_nil
  end

  it 'ignores executions that are not active' do
    create(:workflow_execution, account: account, status: :completed, wake_at: 1.minute.ago)
    expect(Workflows::AdvanceJob).not_to receive(:perform_later)
    described_class.perform_now
  end
end
