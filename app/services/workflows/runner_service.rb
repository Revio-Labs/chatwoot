# Walks a WorkflowExecution's flow_snapshot graph. Executes action nodes
# sequentially and stops at input-wait nodes (send_buttons, send_form,
# collect_input) until the customer's next message advances it.
class Workflows::RunnerService
  include Workflows::ConditionEvaluator

  INPUT_WAIT_NODE_TYPES = %w[send_buttons send_form collect_input].freeze
  MAX_STEPS_PER_ADVANCE = 25

  pattr_initialize [:execution!]

  delegate :conversation, to: :execution

  def perform(message: nil)
    return unless execution.active?
    return unless conversation.pending?

    if execution.current_node_id.blank?
      walk_from(start_node)
    else
      save_collected_input(message) if message.present?
      edge = matching_edge(message)
      # No matching edge: stay at the wait node (persist any collected input).
      return execution.save! if edge.blank?

      walk_from(find_node(edge['to']))
    end
  end

  private

  def start_node
    execution.nodes.first
  end

  def find_node(node_id)
    execution.nodes.find { |node| node['id'] == node_id }
  end

  def walk_from(node)
    steps = 0
    while node.present? && steps < MAX_STEPS_PER_ADVANCE
      execution.record_step(node['id'])
      result = execute_node(node)
      execution.save!
      break if result == :wait || result == :halt

      node = follow_edge(node)
      steps += 1
    end
    terminate_execution if node.blank? && execution.active?
  end

  # Follows the outgoing edge of a non-input node: condition edges first
  # (top-to-bottom, first match), then fallback, then a plain edge.
  def follow_edge(node)
    outgoing = edges_from(node['id'])
    matched = condition_edge(outgoing) || fallback_edge(outgoing)
    matched.present? ? find_node(matched['to']) : nil
  end

  # Matches the customer's reply against the current node's outgoing edges.
  def matching_edge(message)
    outgoing = edges_from(execution.current_node_id)
    button_edge(outgoing, reply_value(message)) || condition_edge(outgoing) || fallback_edge(outgoing)
  end

  def edges_from(node_id)
    execution.edges.select { |edge| edge['from'] == node_id }
  end

  def button_edge(edges, reply)
    edges.find { |edge| edge.dig('match', 'type') == 'button' && edge.dig('match', 'value') == reply }
  end

  def condition_edge(edges)
    edges.find { |edge| edge.dig('match', 'type') == 'condition' && conditions_met?(edge.dig('match', 'conditions')) }
  end

  def fallback_edge(edges)
    edges.find { |edge| edge.dig('match', 'type') == 'fallback' || edge['match'].blank? }
  end

  def reply_value(message)
    return if message.blank?

    submitted = message.content_attributes[:submitted_values] || message.content_attributes['submitted_values']
    submitted&.first&.with_indifferent_access&.[](:value) || message.content
  end

  def save_collected_input(message)
    node = execution.current_node
    return if node.blank?

    Tickets::CreateFromFormService.from_workflow_node(conversation, node, message)

    return if node['save_to'].blank?

    case node['type']
    when 'collect_input'
      execution.variables[node['save_to']] = message.content
    when 'send_form'
      execution.variables[node['save_to']] = message.content_attributes['submitted_values']
    end
  end

  # Dispatches a node to its execute_<type> handler; unknown types no-op.
  def execute_node(node)
    handler = "execute_#{node['type']}"
    respond_to?(handler, true) ? send(handler, node) : :continue
  end

  def execute_send_message(node)
    build_message(content: node['content'])
    :continue
  end

  def execute_send_buttons(node)
    build_message(content: node['content'], content_type: 'input_select', content_attributes: { items: node['items'] })
    :wait
  end

  def execute_send_form(node)
    content_attributes = { items: node['items'] }
    content_attributes[:ticket_type_id] = node['ticket_type_id'] if node['ticket_type_id'].present?
    build_message(content: node['content'], content_type: 'form', content_attributes: content_attributes)
    :wait
  end

  def execute_collect_input(node)
    build_message(content: node['content'])
    :wait
  end

  def execute_set_attribute(node)
    target = node['scope'] == 'conversation' ? conversation : conversation.contact
    target.custom_attributes = (target.custom_attributes || {}).merge(node['key'] => node['value'])
    target.save!
    :continue
  end

  def execute_branch(_node)
    :continue
  end

  def execute_assign_team(node)
    conversation.update!(team_id: node['team_id'])
    :continue
  end

  def execute_assign_agent(node)
    conversation.update!(assignee_id: node['agent_id'])
    :continue
  end

  def execute_add_label(node)
    conversation.reload.add_labels([node['label']])
    :continue
  end

  def execute_toggle_priority(node)
    conversation.update!(priority: node['priority'])
    :continue
  end

  def execute_delay(node)
    execution.wake_at = Time.current + node['seconds'].to_i.seconds
    :wait
  end

  def execute_handoff_workflow(node)
    target = conversation.account.workflow_definitions.live.find_by(id: node['workflow_definition_id'])
    execution.completed!
    return :halt if target.blank?

    new_execution = conversation.workflow_executions.create!(
      account_id: conversation.account_id, workflow_definition: target,
      flow_snapshot: target.flow, variables: execution.variables, last_activity_at: Time.current
    )
    Workflows::RunnerService.new(execution: new_execution).perform
    :halt
  end

  def execute_handoff_agent(_node)
    execution.handed_off!
    conversation.bot_handoff!
    dispatch_event(Events::Types::WORKFLOW_EXECUTION_HANDED_OFF)
    :halt
  end

  def execute_resolve(_node)
    execution.update!(status: :completed, completed_at: Time.current)
    conversation.resolved!
    dispatch_event(Events::Types::WORKFLOW_EXECUTION_COMPLETED)
    :halt
  end

  def terminate_execution
    execution.update!(status: :completed, completed_at: Time.current)
    dispatch_event(Events::Types::WORKFLOW_EXECUTION_COMPLETED)
    nil
  end

  def build_message(params)
    Messages::MessageBuilder.new(
      nil,
      conversation,
      params.merge(sender_type: 'AgentBot', sender_id: workflow_bot.id)
    ).perform
  end

  def workflow_bot
    @workflow_bot ||= AgentBot.find_or_create_by!(account_id: conversation.account_id, bot_type: :workflow) do |bot|
      bot.name = 'Workflow Bot'
    end
  end

  def dispatch_event(event_name)
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, execution: execution, conversation: conversation)
  end
end
