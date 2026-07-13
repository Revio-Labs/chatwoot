require 'rails_helper'

RSpec.describe Workflows::AdvanceJob do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, status: :pending) }

  it 'triggers a new workflow when there is no active execution and no message' do
    expect(Workflows::TriggerService).to receive(:new).with(conversation: conversation).and_call_original
    allow_any_instance_of(Workflows::TriggerService).to receive(:perform)
    described_class.perform_now(conversation.id)
  end

  it 'advances the active execution when one exists' do
    definition = create(:workflow_definition, account: account, inbox: conversation.inbox)
    execution = create(:workflow_execution, account: account, conversation: conversation,
                                            workflow_definition: definition, status: :active)
    runner = instance_double(Workflows::RunnerService, perform: nil)
    expect(Workflows::RunnerService).to receive(:new).with(execution: execution).and_return(runner)
    described_class.perform_now(conversation.id)
  end

  it 'no-ops for a missing conversation' do
    expect { described_class.perform_now(0) }.not_to raise_error
  end
end
