require 'json'

When /^I add dependencies to (deplist.txt|package.json) on node modules(.*)$/ do |depfile, modules|
    Dir.chdir(@app.repo) do
      case depfile.strip
      when "deplist.txt"
        run("echo -e '#{modules.gsub(" ", "\n")}' >> ./deplist.txt")
      when "package.json"
        pkg = ""
        File.open("package.json") { |f| pkg = JSON.parse(f.read) }
        modules.split.each { |m| pkg['dependencies'][m] = "*" }
        File.open("package.json", "w") { |f| f.write(JSON.dump(pkg)) }
      end
      run("git commit -a -m 'Test change'")
      run("git push >> " + @app.get_log("git_push_nodejs_deps") + " 2>&1")
    end
end

When /^the use_npm marker is (added|removed)$/ do |action|
  Dir.chdir(@app.repo) do
    if action == 'added'
      run("touch .openshift/markers/use_npm")
      run("git add .openshift")
    end
    if action == 'removed'
      run("git rm .openshift/markers/use_npm")
    end
    run("git commit -a -m 'Test change'")
    run("git push >> " + @app.get_log("git_push_nodejs_npm_marker_#{action}") + " 2>&1")
  end
end

Then /^the application should run using (npm|supervisor)/ do |server|
  #
  # When use_npm marker is enabled, this line should be printed during git push:
  #
  # *** NodeJS supervisor is disabled due to .openshift/markers/use_npm
  #
  if server == 'npm'
    log_file = File.readlines(@app.get_log('git_push_nodejs_npm_marker_added'))
    raise "Supervisor not disabled" unless log_file.grep(/supervisor is disabled/).any?
  end
  if server == 'supervisor'
    log_file = File.readlines(@app.get_log('git_push_nodejs_npm_marker_removed'))
    raise "Supervisor is disabled" if log_file.grep(/supervisor is disabled/).any?
  end
end

Then /^the application will have the (.*) node modules installed$/ do |modules| 
  app_dir = File.join("/var/lib/openshift", @app.uid)
  node_mods_dir = File.join(app_dir, ".node_modules")
  repo_mods_dir = File.join(app_dir, "app-root", "repo", "node_modules")
  modules.split.each do |m|
    if !File.directory?(File.join(node_mods_dir, m))  &&
       !File.directory?(File.join(repo_mods_dir, m))
      print "Missing node_modules dir for #{m}"
      raise "Missing node_modules dir for #{m}"
    end
  end
end

