# Must be the first module imported at entry points (executables that run
# in separate processes from the test harness) otherwise coverage will be
# incomplete

require 'simplecov'
SimpleCov.start 'rails' do
  coverage_dir 'test/coverage/'
  command_name ENV["TEST_NAME"] || 'broker tests'

  # Filters - these files will be ignored.
  add_filter '/test/'

  merge_timeout 1000
end
