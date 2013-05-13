class Rake::Task
  def abandon
    prerequisites.clear
    @actions.clear
  end
end

Rake::TestTask.new :test do |i|
  i.test_files = FileList['test/**/*_test.rb']
end
task :test => 'test:prepare'

namespace :test do
  namespace :prepare do
    task :ci_reporter do
      # define our own ci_reporter task to NOT delete test reports (can't run in parallel if we're deleting)
      begin 
        require 'ci/reporter/rake/minitest'
        path = File.join(Gem.loaded_specs["ci_reporter"].full_gem_path, 'lib', 'ci', 'reporter', 'rake', 'minitest_loader.rb')
        test_loader = CI::Reporter.maybe_quote_filename path
        ENV["TESTOPTS"] = "#{ENV["TESTOPTS"]} #{test_loader}"
      rescue Exception
        # ci_reporter is optional in the gemfile
      end
    end
  end
  task :prepare => 'test:prepare:ci_reporter'

  Rake::TestTask.new :restapi => 'test:prepare' do |t|
    t.libs << 'test'
    t.test_files = FileList[
      'test/**/rest_api_test.rb',
      'test/**/rest_api/*_test.rb',
    ]
  end

  namespace :check do
    covered = []

    Rake::TestTask.new :applications => ['test:prepare'] do |t|
      t.libs << 'test'
      covered.concat(t.test_files = FileList[
        'test/functional/applications_controller_sanity_test.rb',
      ])
    end

    Rake::TestTask.new :cartridges => ['test:prepare'] do |t|
      t.libs << 'test'
      covered.concat(t.test_files = FileList[
        'test/functional/cartridges_controller_test.rb',
        'test/functional/cartridge_types_controller_test.rb',
      ])
    end

    Rake::TestTask.new :misc1 => ['test:prepare'] do |t|
      t.libs << 'test'
      covered.concat(t.test_files = FileList[
        'test/functional/applications_controller_test.rb',
        'test/functional/application_types_controller_test.rb',
        'test/functional/domains_controller_test.rb',
        'test/functional/scaling_controller_test.rb',
        'test/integration/rest_api/cartridge_test.rb',
      ])
    end

    Rake::TestTask.new :restapi_integration => ['test:prepare'] do |t|
      t.libs << 'test'
      covered.concat(t.test_files = FileList[
        'test/integration/rest_api/**_test.rb',
      ].exclude('test/integration/rest_api/cartridge_test.rb'))
    end

    Rake::TestTask.new :base => ['test:prepare'] do |t|
      t.libs << 'test'
      t.test_files = FileList['test/**/*_test.rb'] - covered
    end
  end
  task :check => Rake::Task.tasks.select{ |t| t.name.match(/\Atest:check:/) }.map(&:name)
  task :extended => []
end
