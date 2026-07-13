require 'rails_helper'

# Property-style test: for many randomly generated linear flows the runner must
# never raise and must always reach a terminal (completed) state.
RSpec.describe Workflows::RunnerService, type: :property do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_widget, account: account)) }
  let(:definition) { create(:workflow_definition, account: account, inbox: inbox) }

  # Action nodes that run to completion without waiting for customer input.
  NON_WAIT_NODES = [
    ->(id) { { 'id' => id, 'type' => 'send_message', 'content' => "msg #{id}" } },
    ->(id) { { 'id' => id, 'type' => 'set_attribute', 'scope' => 'contact', 'key' => "k#{id}", 'value' => 'v' } },
    ->(id) { { 'id' => id, 'type' => 'add_label', 'label' => "l#{id}" } },
    ->(id) { { 'id' => id, 'type' => 'toggle_priority', 'priority' => 'high' } },
    ->(id) { { 'id' => id, 'type' => 'branch' } }
  ].freeze

  def random_linear_flow(rng, length)
    nodes = []
    edges = []
    length.times do |i|
      id = "n#{i}"
      nodes << NON_WAIT_NODES.sample(random: rng).call(id)
      edges << { 'from' => "n#{i - 1}", 'to' => id } if i.positive?
    end
    terminal = "t#{length}"
    nodes << { 'id' => terminal, 'type' => 'resolve' }
    edges << { 'from' => "n#{length - 1}", 'to' => terminal } if length.positive?
    { 'nodes' => nodes, 'edges' => edges }
  end

  it 'never raises and always terminates for random linear flows' do
    rng = Random.new(20260713)
    20.times do
      conversation = create(:conversation, account: account, inbox: inbox, status: :pending)
      flow = random_linear_flow(rng, rng.rand(1..6))
      execution = create(:workflow_execution, account: account, conversation: conversation,
                                              workflow_definition: definition, flow_snapshot: flow)

      expect { described_class.new(execution: execution).perform }.not_to raise_error
      expect(execution.reload).to be_completed
    end
  end
end
