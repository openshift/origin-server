# step descriptions for Perl cartridge specific behavior.

require 'fileutils'

include AppHelper

When /^the application document root is changed to ([^ ]*) directory$/ do |directory|
    Dir.chdir(@app.repo) do
      run("mkdir -p #{directory}")
      run("mv index.pl .htaccess #{directory}/")
      run("git add perl/")
      run("git commit -am 'Test commit - Change document root'")
      run("git push >> " + @app.get_log("git_push_php_create_file") + " 2>&1")
    end
end

When /^the application document root is changed from ([^ ]*) directory back to default directory$/ do |directory|
    Dir.chdir(@app.repo) do
      run("mv #{directory}/* ./")
      run("rm -rf #{directory}/")
      run("git add .")
      run("git rm #{directory}/")
      run("git commit -am 'Test commit - Change document root back to default directory'")
      run("git push >> " + @app.get_log("git_push_php_create_file") + " 2>&1")
    end
end