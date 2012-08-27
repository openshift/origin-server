require 'ci/reporter/rake/test_unit'

namespace :test do

  namespace :prepare do
    task :ci_reporter do
      # removed deletion of test cases
      path = File.join(Gem.loaded_specs["ci_reporter"].full_gem_path, 'lib', 'ci', 'reporter', 'rake', 'test_unit_loader.rb')
      test_loader = CI::Reporter.maybe_quote_filename path
      ENV["TESTOPTS"] = "#{ENV["TESTOPTS"]} #{test_loader}"
    end
  end
  task 'test:prepare' => 'test:prepare:ci_reporter'

  Rake::TestTask.new :restapi => 'test:prepare' do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/**/rest_api_test.rb',
      'test/**/rest_api/*_test.rb',
    ]
  end

  task :check => Rake::Task.tasks.select{ |t| t.name.match(/\Atest:check:/) }.map(&:name)
  task :extended => []
end
