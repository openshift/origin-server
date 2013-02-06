# Must be the first module imported at entry points (executables that run
# in separate processes from the test harness) otherwise coverage will be
# incomplete

require 'simplecov'
SimpleCov.start do
  coverage_dir 'test/coverage/'
  command_name ENV["TEST_NAME"] || 'node tests'

  add_group 'Models', 'lib/openshift-origin-node/model'
  add_group 'Plugins', 'lib/openshift-origin-node/plugins'
  add_group 'Utils', 'lib/openshift-origin-node/utils'

  # Filters - these files will be ignored.
  add_filter '/test/'

  merge_timeout 1000
end
