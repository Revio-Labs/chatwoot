json.payload do
  json.array! @workflows do |workflow|
    json.partial! 'api/v1/accounts/workflows/partials/workflow', formats: [:json], workflow: workflow
  end
end
