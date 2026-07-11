# Creates a Ticket from a widget form submission (content_type: form).
# The bot/workflow sends a `form` message whose content_attributes carry a
# ticket_type_id; on submission the collected submitted_values become the
# ticket's custom_attributes.
class Tickets::CreateFromFormService
  pattr_initialize [:conversation!, :ticket_type!, { submitted_values: [] }]

  # Convenience entry point for the workflow runner: a send_form node carrying a
  # ticket_type_id creates a ticket from the submitted form values. No-op otherwise.
  def self.from_workflow_node(conversation, node, message)
    return unless node['type'] == 'send_form' && node['ticket_type_id'].present?

    ticket_type = conversation.account.ticket_types.find_by(id: node['ticket_type_id'])
    return if ticket_type.blank?

    new(conversation: conversation, ticket_type: ticket_type,
        submitted_values: message.content_attributes['submitted_values'] || []).perform
  end

  def perform
    ticket = conversation.account.tickets.create!(
      ticket_type: ticket_type,
      conversation: conversation,
      contact: conversation.contact,
      team: conversation.team,
      title: ticket_title,
      custom_attributes: attributes_from_submission
    )
    link_conversation(ticket)
    ticket
  end

  private

  def attributes_from_submission
    Array(submitted_values).each_with_object({}) do |field, acc|
      key = field['name'] || field[:name]
      acc[key] = field['value'] || field[:value] if key.present?
    end
  end

  def ticket_title
    "#{ticket_type.name} ##{conversation.display_id}"
  end

  def link_conversation(ticket)
    ticket.ticket_links.create!(account: conversation.account, conversation: conversation)
  end
end
