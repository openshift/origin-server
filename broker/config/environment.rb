# Load the rails application
require File.expand_path('../application', __FILE__)

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.adapters.delete(:root_filter)
  SimpleCov.filters.clear
  
  class ProjectFilter < SimpleCov::Filter
    def matches?(source_file)
      engines = Rails.application.railties.engines.map { |e| e.config.root.to_s }
      engines.each do |root_path|
        return false if source_file.filename.start_with? root_path
      end
      return true
    end
  end
  SimpleCov.add_filter ProjectFilter.new(nil)
  
  SimpleCov.start 'rails' do
    coverage_dir 'test/coverage/'
    command_name ENV["TEST_NAME"] || 'Broker tests'
    add_group 'REST API Models', 'app/rest_models'
    add_group 'Validators', 'app/validators'

    merge_timeout 10000
  end
end

# Initialize the rails application
Broker::Application.initialize!
