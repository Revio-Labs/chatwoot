# Coverage gate for the workflow engine + tickets. Only activates when the
# WORKFLOW_COVERAGE env var is set (the workflow_engine CI job), so it never
# affects the normal suite. Must start before the app is loaded.
if ENV['WORKFLOW_COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails' do
    track_files 'app/**/*.rb'
    add_filter { |source| !source.filename.match?(%r{/(workflow|ticket)}i) }
    minimum_coverage 85
  end
end

require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  def with_modified_env(options, &)
    ClimateControl.modify(options, &)
  end
end
