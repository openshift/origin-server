require 'json'

When /^I add dependencies to (deplist.txt|package.json) on node modules(.*)$/ do |depfile, modules|
    Dir.chdir(@app.repo) do
      case depfile.strip
      when "deplist.txt"
        run("echo -e '#{modules.gsub(" ", "\n")}' >> ./deplist.txt")
      when "package.json"
        pkg = ""
        File.open("package.json") { |f| pkg = JSON.parse(f.readlines.to_s) }
        modules.split.each { |m| pkg['dependencies'][m] = "*" }
        File.open("package.json", "w") { |f| f.write(JSON.dump(pkg)) }
      end
      run("git commit -a -m 'Test change'")
      run("git push >> " + @app.get_log("git_push_nodejs_deps") + " 2>&1")
    end
end

Then /^the application will have the (.*) node modules installed$/ do |modules| 
  app_dir = File.join("/var/lib/stickshift", @app.uid, @app.type)
  node_mods_dir = File.join(app_dir, "node_modules")
  repo_mods_dir = File.join(app_dir, "repo", "node_modules")
  modules.split.each do |m|
    if !File.directory?(File.join(node_mods_dir, m))  &&
       !File.directory?(File.join(repo_mods_dir, m))
      raise "Missing node_modules dir for #{m}"
    end
  end
end

