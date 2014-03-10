# step descriptions for Perl cartridge specific behavior.

require 'fileutils'

include AppHelper

When /^the application document root is changed to ([^ ]*) directory$/ do |directory|
    Dir.chdir(@app.repo) do
      run("mkdir -p #{directory}")
      run("mv index.pl .htaccess #{directory}/")
      run("git add perl/")
      run("git commit -am 'Test commit - Change document root'")
      run("git push >> " + @app.get_log("git_push_perl_create_file") + " 2>&1")
    end
end

When /^the application document root is changed from ([^ ]*) directory back to default directory$/ do |directory|
    Dir.chdir(@app.repo) do
      run("mv #{directory}/* ./")
      run("rm -rf #{directory}/")
      run("git add .")
      run("git rm #{directory}/")
      run("git commit -am 'Test commit - Change document root back to default directory'")
      run("git push >> " + @app.get_log("git_push_perl_create_file") + " 2>&1")
    end
end

When /^a cpanfile is added into repo directory$/ do
    Dir.chdir(@app.repo) do
      File.open("cpanfile",'w') {|f| f.write('requires "YAML", "== 0.90";')}
      run("git add cpanfile")
      run("git commit -m 'Test commit - Adding cpanfile into repo'")
      run("git push >> " + @app.get_log("git_push_perl_create_file") + " 2>&1")
    end
end

When /^a Makefile is added into repo directory$/ do
    Dir.chdir(@app.repo) do
      File.open("Makefile",'w') do |f|
        f.write('use strict;')
        f.write('use warnings;')
        f.write('use ExtUtils::MakeMaker;')
        f.write('WriteMakefile(PREREQ_PM => {"YAML" => "0.90"});')
      end
      run("git add cpanfile")
      run("git commit -m 'Test commit - Adding cpanfile into repo'")
      run("git push >> " + @app.get_log("git_push_perl_create_file") + " 2>&1")
    end
end