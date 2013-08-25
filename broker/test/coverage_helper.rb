# Must be the first module imported at entry points (executables that run
# in separate processes from the test harness) otherwise coverage will be
# incomplete

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

class StringFilter < SimpleCov::Filter
  # Returns true when the given source file's filename matches the
  # string configured when initializing this Filter with StringFilter.new('somestring)
  def matches?(source_file)
    (source_file.filename =~ /#{filter_argument}/)
  end
end

SimpleCov.add_filter StringFilter.new("openshift-origin-billing")
SimpleCov.add_filter StringFilter.new("openshift-origin-dns")
SimpleCov.add_filter StringFilter.new("openshift-origin-auth")
SimpleCov.add_filter StringFilter.new("openshift-origin-admin-console")

COVERAGE_DIR = 'test/coverage/'
RESULT_SET = File.join(COVERAGE_DIR, '.resultset.json')

FileUtils.mkpath COVERAGE_DIR

SimpleCov.start 'rails' do
  coverage_dir COVERAGE_DIR
  command_name ENV["TEST_NAME"] || 'broker tests'
  add_group 'REST API Models', 'app/rest_models'
  add_group 'Validators', 'app/validators'

  merge_timeout 10000
end

FileUtils.touch(RESULT_SET)
FileUtils.chmod_R(01777, COVERAGE_DIR)
