require 'fileutils'

When /^the jboss application is changed to multiartifact$/ do
  Dir.chdir(@app.repo) do
    @update = """<executions>
              <execution>
                <goals><goal>war</goal></goals>
                <phase>package</phase>
                <configuration>
                  <outputDirectory>deployments</outputDirectory>
                  <warName>ROOT</warName>
                </configuration>
              </execution>
              <execution>
                <id>test3-archive</id>
                <goals><goal>war</goal></goals>
                <phase>package</phase>
                <configuration>
                  <outputDirectory>deployments</outputDirectory>
                  <warName>test3</warName>
                </configuration>
              </execution>
              <execution>
                <id>test-exploded</id>
                <goals><goal>exploded</goal></goals>
                <phase>package</phase>
                <configuration>
                  <webappDirectory>deployments/exploded/test.war</webappDirectory>
                  <warName>test</warName>
                </configuration>
              </execution>
              <execution>
                <id>test2-exploded</id>
                <goals><goal>exploded</goal></goals>
                <phase>package</phase>
                <configuration>
                  <webappDirectory>deployments/exploded/test2.war</webappDirectory>
                  <warName>test2</warName>
                </configuration>
              </execution>
            </executions>""".gsub(/\s+/, "")
    # Make a change to the app pom file
    run("sed -i -e \"/<configuration>/,/<\\\/configuration>/c #{@update}\" #{@app.get_pom_file}")
    run("git commit -a -m 'Test change'")
    run("git push >> " + @app.get_log("git_push_multiartifact") + " 2>&1")
  end
end

When /^the jboss application deployment-scanner is changed to (archive only|exploded only|none|all|disabled)$/ do |scanner_config|
  Dir.chdir(@app.repo) do
    matchbegin = '<subsystem xmlns=\"urn:jboss:domain:deployment-scanner:1.1\">'
    matchend = '<\/subsystem>'
    @update = '<deployment-scanner path=\"deployments\" relative-to=\"jboss.server.base.dir\" '
    @update << 'scan-interval=\"5000\" deployment-timeout=\"300\" '
    log_postfix = scanner_config.split(/ /)[0]

    case scanner_config
    when 'exploded only'
      @update << 'auto-deploy-zipped=\"false\" auto-deploy-exploded=\"true\"'
    when 'none'
      @update << 'auto-deploy-zipped=\"false\" auto-deploy-exploded=\"false\"'
    when 'all'
      @update << 'auto-deploy-exploded=\"true\"'
    when 'disabled'
      @update << 'scan-enabled=\"false\"'
    end
    @update << "/>"
    run("awk '/#{matchbegin}/{p=1; print; print \"#{@update}\"}/#{matchend}/{p=0}!p' #{@app.get_standalone_config} > #{@app.get_standalone_config}.new")
    run("mv #{@app.get_standalone_config}.new #{@app.get_standalone_config}")
    run("git commit -a -m 'Test change'")
    run("git push >> " + @app.get_log("git_push_scanner_config_#{log_postfix}") + " 2>&1")
  end
end

When /^the jboss management interface is disabled$/ do
  Dir.chdir(@app.repo) do
    run("sed -i -e \"/<native-interface>/,/<\\\/native-interface>/d\" #{@app.get_standalone_config}")
    run("git commit -a -m 'Test change'")
    run("git push >> " + @app.get_log("git_push_disabled_management") + " 2>&1")
  end
end

Then /^the application should display default content for deployed artifacts on first attempt$/ do
  output=[]
  result = run("grep 'Artifacts deployed:' " + @app.get_log("git_push_multiartifact"), output)
  result.should == 0

  artifacts=output[0].split(':')[2].split(' ')

  # Verify content for each artifact (ROOT.war should be / others should be /<artifact name>
  artifacts.each do |artifact|
    # strip out pathnames, file extension and trailing junk
    artifact = artifact.gsub(/\.\/exploded\//, "").gsub(/\.\//, "").gsub(/\.war.*/, "")
    if artifact == "ROOT"
      body = @app.connect(false,1,5)
      body.should match(/Welcome/)
    else
      # should connect to URL of artifact and not /
      body = @app.connect(false,1,5,"/#{artifact}/")
      body.should match(/Welcome/)
    end
  end
end

Then /^deployment verification should be skipped with (scanner disabled|management unavailable) message$/ do |reason|
  case reason
  when "scanner disabled"
    logfile = @app.get_log("git_push_scanner_config_disabled")
    run("grep 'Deployment scanner disabled, skipping deployment verification' " + logfile).should == 0
  when "management unavailable"
    logfile = @app.get_log("git_push_disabled_management")
    run("grep 'Could not connect to JBoss management interface, skipping deployment verification' " + logfile).should == 0
  end

  run("grep 'Failed deployments:' " + logfile).should_not == 0
  run("grep 'Artifacts in an unknown state:' " + logfile).should_not == 0
  run("grep 'Artifacts skipped because of deployment-scanner configuration:' " + logfile).should_not == 0
  run("grep 'Artifacts deployed:' " + logfile).should_not == 0
end

Then /^(only exploded|only archive|no|all|default) artifacts should be deployed$/ do |scanner_config|
  case scanner_config
  when 'no'
    log_postfix = "none"
  when 'all'
    log_postfix = "all"
  when 'only exploded'
    log_postfix = "exploded"
  when 'only archive'
    log_postfix = "archive"
  when 'default'
    log_postfix = "multiartifact"
  end

  logfile = @app.get_log("git_push_scanner_config_#{log_postfix}")

  failedresult = run("grep 'Failed deployments:' " + logfile)
  unknownresult = run("grep 'Artifacts in an unknown state:' " + logfile)
  failedresult.should_not == 0
  unknownresult.should_not == 0

  skippedoutput = []
  skippedresult = run("grep 'Artifacts skipped because of deployment-scanner configuration:' " + logfile,
                      skippedoutput)

  deployedoutput = []
  deployedresult = run("grep 'Artifacts deployed:' " + logfile, deployedoutput)

  cartdir = @app.type.split('-')[0]
  deploydir = "#{cartdir}/standalone/deployments"
  regex = '".*\.\([ejrsw]ar\|zip\)$"'
  commandprefix = "'cd " + deploydir + " && find . "
  commandpostfix = " -iregex " + regex + " -print0'"
  exploded = @app.ssh_command(commandprefix + "-type d" + commandpostfix).split("\0")
  archived = @app.ssh_command(commandprefix + "-type f" + commandpostfix).split("\0")

  case scanner_config
  when 'only archive'
    skippedresult.should == 0
    deployedresult.should == 0
    exploded.each do |artifact|
      skippedoutput[0].should match(artifact)
      deployedoutput[0].should_not match(artifact)
    end
    archived.each do |artifact|
      skippedoutput[0].should_not match(artifact)
      deployedoutput[0].should match(artifact)
    end
  when 'only exploded'
    skippedresult.should == 0
    deployedresult.should == 0
    exploded.each do |artifact|
      skippedoutput[0].should_not match(artifact)
      deployedoutput[0].should match(artifact)
    end
    archived.each do |artifact|
      skippedoutput[0].should match(artifact)
      deployedoutput[0].should_not match(artifact)
    end
  when 'no'
    skippedresult.should == 0
    deployedresult.should_not == 0
    exploded.concat(archived).each do |artifact|
      skippedoutput[0].should match(artifact)
    end
  when 'all'
    skippedresult.should_not == 0
    deployedresult.should == 0
    exploded.concat(archived).each do |artifact|
      deployedoutput[0].should match(artifact)
    end
  end
end

When /^the jboss repository config file is renamed$/ do
  Dir.chdir(@app.repo) do
    # rename the standalone.xml so it will not be found
    run("git mv .openshift/config/standalone.xml .openshift/config/standalone.bak")
    run("git commit -a -m 'Test change'")
    run("git push >> " + @app.get_log("git_push") + " 2>&1")
  end
end

When /^the jboss repository config file is restored( without restart)$/ do |norestart|
  Dir.chdir(@app.repo) do
    # rename the standalone.xml so it will be found
    run("git mv .openshift/config/standalone.bak .openshift/config/standalone.xml")
    run("git commit -a -m 'Test change'")
    run("git push >> " + @app.get_log("git_push") + " 2>&1") unless norestart
  end
end

When /^a property with key (.*?) and value (.*?) is added to the (.*?) repository config$/ do |key,value, jboss|
  Dir.chdir(@app.repo) do
    # Make a change to the standalone.xml
    if jboss == "jboss"
      run("sed -i 's/<system-properties>/<system-properties>\\n<property name=\"#{key}\" value=\"#{value}\"\\/>/' .openshift/config/standalone.xml")
    end
    if jboss == "wildfly"
      run("sed -i 's/<\\/extensions>/<\\/extensions>\\n<system-properties>\\n<property name=\"#{key}\" value=\"#{value}\"\\/><\\/system-properties>\\n/' .openshift/config/standalone.xml")
    end
    run("git commit -a -m 'Test change'")
    run("git push >> " + @app.get_log("git_push") + " 2>&1")
  end
end

When /^a property with key (.*?) and value (.*?) is added directly to the (.*?) config$/ do |key,value,jboss|
  if jboss =~ /JBOSS/
    @app.ssh_command("sed -i \\'s/\\<system-properties\\>/\\<system-properties\\>\\\\n\\<property name=\\\"#{key}\\\" value=\\\"#{value}\\\"\\\\/\\>/\\' \\$OPENSHIFT_#{jboss}_DIR/standalone/configuration/standalone.xml")
  end
  if jboss == "WILDFLY"
    @app.ssh_command("sed -i \\'s/\\<\\/extensions>/\\<\\/extensions\\>\\\\n\\<system-properties\\>\\\\n\\<property name=\\\"#{key}\\\" value=\\\"#{value}\\\"\\\\/\\>\\<\\\\/system-properties\\>\\\\n/ \\$OPENSHIFT_#{jboss}_DIR/standalone/configuration/standalone.xml")
  end
end

Then /^the (.*?) config will( not)? contain a property with the value (.*?)$/ do |jboss,negate,value|
  @app.ssh_command("'grep #{value} $OPENSHIFT_#{jboss}_DIR/standalone/configuration/standalone.xml'")
  exit_status = $?.exitstatus
  if negate
    exit_status.should_not eq 0
  else
    exit_status.should eq 0
  end
end

