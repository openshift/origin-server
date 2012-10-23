namespace :engine do
  desc "Report code statistics (KLOCs, etc) from the application"
  task :stats do
    ENGINE_STATS_DIRECTORIES = [
      %w(Controllers        app/controllers),
      %w(Helpers            app/helpers),
      %w(Models             app/models),
      %w(Libraries          lib/),
      %w(APIs               app/apis),
      %w(Integration\ tests test/integration),
      %w(Functional\ tests  test/functional),
      %w(Unit\ tests        test/unit)
    ].collect { |name, dir| [ name, "#{ENGINE_PATH}/#{dir}" ] }.select { |name, dir| File.directory?(dir) }

    require 'rails/code_statistics'
    CodeStatistics.new(*ENGINE_STATS_DIRECTORIES).to_s
  end
end
