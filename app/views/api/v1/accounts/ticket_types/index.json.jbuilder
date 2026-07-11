json.payload do
  json.array! @ticket_types do |ticket_type|
    json.partial! 'api/v1/accounts/ticket_types/partials/ticket_type', formats: [:json], ticket_type: ticket_type
  end
end
