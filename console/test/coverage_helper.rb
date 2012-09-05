# Must be the first module imported at entry points (executables that run
# in seperate processes from the test harness) otherwise coverage will be
# incomplete

require 'simplecov'
SimpleCov.start 'rails' do
  coverage_dir 'test/coverage/'
  command_name 'Console tests'

  # Filters - these files will be ignored.
  add_filter 'app/models/rest_api/railties'

  # Groups - general categories of test areas
  #add_group('Controllers') { |src_file| src_file.filename.include?(File.join(%w[lib rhc commands])) }
  #add_group('REST API')    { |src_file| src_file.filename.include?(File.join(%w[lib rhc])) }
  #add_group('REST')        { |src_file| src_file.filename.include?(File.join(%w[lib rhc/rest])) }  
  #add_group('Legacy')      { |src_file| src_file.filename.include?(File.join(%w[bin])) or
  #                                      src_file.filename.include?(File.join(%w[lib rhc-common.rb])) }
  #add_group('Test')        { |src_file| src_file.filename.include?(File.join(%w[features])) or
  #                                      src_file.filename.include?(File.join(%w[spec])) }

  #use_merging = true
  # Note, the #:nocov: coverage exclusion  should only be used on external functions 
  #  that cannot be nondestructively tested in a developer environment.
end
