# Must be the first module imported at entry points (executables that run
# in separate processes from the test harness) otherwise coverage will be
# incomplete

require 'simplecov'

# guard so oo_spawn tests that change UID don't break
COVERAGE_DIR = 'test/coverage/'
RESULT_SET = File.join(COVERAGE_DIR, '.resultset.json')

FileUtils.mkpath COVERAGE_DIR

SimpleCov.start do
  coverage_dir COVERAGE_DIR
  command_name ENV["TEST_NAME"] || 'node tests'

  add_group 'Models', 'lib/openshift-origin-node/model'
  add_group 'Plugins', 'lib/openshift-origin-node/plugins'
  add_group 'Utils', 'lib/openshift-origin-node/utils'

  # Filters - these files will be ignored.
  add_filter '/test/'

  merge_timeout 1000
end


FileUtils.touch(File.join(COVERAGE_DIR, '.resultset.json'))
FileUtils.chmod_R(01777, COVERAGE_DIR)
