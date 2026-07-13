require 'rails_helper'

RSpec.describe WorkflowFlowValidator do
  # Minimal host record exercising the validator directly.
  let(:validatable) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :flow

      validates :flow, workflow_flow: true
    end
  end

  def record_with(flow)
    validatable.new.tap { |r| r.flow = flow }
  end

  it 'passes for a nil/blank flow' do
    expect(record_with(nil)).to be_valid
  end

  it 'fails when nodes is not an array' do
    record = record_with('nodes' => 'oops')
    expect(record).not_to be_valid
  end

  it 'passes for a small valid flow' do
    expect(record_with('nodes' => [{ 'id' => 'a' }], 'edges' => [])).to be_valid
  end

  it 'fails above the node cap' do
    nodes = Array.new(WorkflowFlowValidator::MAX_NODES + 1) { |i| { 'id' => i.to_s } }
    expect(record_with('nodes' => nodes)).not_to be_valid
  end

  it 'fails above the byte-size cap' do
    huge = { 'nodes' => [{ 'id' => 'a', 'content' => 'x' * (WorkflowFlowValidator::MAX_BYTESIZE + 1) }] }
    expect(record_with(huge)).not_to be_valid
  end
end
