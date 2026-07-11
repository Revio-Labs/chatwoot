json.payload do
  json.array! @tickets do |ticket|
    json.partial! 'api/v1/accounts/tickets/partials/ticket', formats: [:json], ticket: ticket
  end
end
