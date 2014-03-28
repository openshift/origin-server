# Steps specific to the php cartridge.
require 'test/unit'
require 'test/unit/assertions'

include Test::Unit::Assertions

When /^I rename ([^ ]+) repo file as ([^ ]+) file$/ do | oldfile, newfile |
    Dir.chdir(@app.repo) do
      dir = File.dirname(newfile)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      run("git mv #{oldfile} #{newfile}")
      run("git commit -am 'Test commit - Rename #{oldfile} as #{newfile}'")
      run("git push >> " + @app.get_log("git_push_php_create_file") + " 2>&1")
    end
end
