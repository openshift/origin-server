require 'timeout'
require 'fileutils'
require 'open3'
require 'open4'
require 'benchmark'

module CommandHelper
  def run_stdout(cmd)
    $logger.info("Running: #{cmd}")

    exit_code = -1
    output = nil

    # Don't let a command run more than 5 minutes
    Timeout::timeout(500) do
      output = `#{cmd} 2>&1`
      exit_code = $?.exitstatus
    end

    $logger.error("(#{$$}): Execution failed #{cmd} with exit_code: #{exit_code.to_s} and output:\n #{output}") if exit_code != 0
    exit_code.should == 0
    return output
  end

  def run(cmd, outbuf=[], retries=0)
    $logger.info("Running: #{cmd}")

    exit_code = -1
    output = nil

    # Don't let a command run more than 5 minutes
    Timeout::timeout(500) do
      output = `#{cmd} 2>&1`
      exit_code = $?.exitstatus
    end

    $logger.debug("Output:\n#{output}")

    if exit_code != 0
      $logger.error("(#{$$}): Execution failed #{cmd} with exit_code: #{exit_code.to_s}")
      if retries < 3 && exit_code == 140 && cmd.start_with?("/usr/bin/rhc-") #No nodes available...  ugh
        $logger.debug("Restarting #{$gear_update_plugin_service} and retrying")
        $logger.debug `service #{$gear_update_plugin_service} restart`
        sleep 5
        return run(cmd, outbuf, retries+1)
      end
    end

    # append the buffers if an array container is provided
    if outbuf
      outbuf << output
    end

    return exit_code
  end

  # run a command in an alternate SELinux context, if provided
  def runcon(cmd, user=nil, role=nil, type=nil, outbuf=nil, time_limit_sec=600)
    if user.nil? and role.nil? and type.nil?
      exit_code = run cmd, outbuf
      return exit_code
    end

    prefix = 'runcon'
    prefix += (' -u ' + user) if user
    prefix += (' -r ' + role) if role
    prefix += (' -t ' + type) if type
    fullcmd = prefix + " " + cmd

    time_start = Time.now
    output = `#{fullcmd} 2>&1`
    exit_code = $?.exitstatus
    execute_time = Time.now - time_start
    raise "Time limit reached.  Limit: #{time_limit_sec}s Actual: #{execute_time}s" if execute_time > time_limit_sec

    $logger.debug("Command run: #{fullcmd}")
    $logger.debug("Output:\n#{output}")
    $logger.debug("Exit Code: #{exit_code}")
    $logger.debug("Time limit: #{time_limit_sec}s Actual: #{execute_time}s") if time_limit_sec
    # append the buffers if an array container is provided
    if outbuf
      outbuf << output
    end

    $logger.error("(#{$$}): Execution failed #{cmd} with exit_code: #{exit_code.to_s}") if exit_code != 0

    return exit_code
  end

  def log_event(str)
    $perfmon_logger.info "#{Thread.current} #{str}"
  end

  def rhc_sshkey_upload(app, name ='default', key=File.join(ENV["HOME"], '.ssh', 'id_rsa.pub'))
    rhc_do('rhc_sshkey_upload') do
      cmd = "#{$rhc_script} sshkey add -l #{app.login} -p #{app.password} #{name} #{key} --confirm"
      exit_code = 0

      time = Benchmark.realtime do
        exit_code = run(cmd)
      end

      log_event "#{time} SSHKEY_ADD #{name} #{key}"
      return exit_code == 0
    end
  end

  def rhc_create_domain(app)
    rhc_do('rhc_create_domain') do

      exit_code = 0
      time = Benchmark.realtime do 
        exit_code = run("#{$rhc_script} domain create -l #{app.login} -p #{app.password} #{app.namespace} -d")
      end
      log_event "#{time} CREATE_DOMAIN #{app.namespace} #{app.login}"

      app.create_domain_code = exit_code
      return exit_code == 0
    end
  end

  def rhc_update_namespace(app)
    rhc_do('rhc_update_namespace') do
      old_namespace = app.namespace
      if old_namespace.end_with?('new')
        app.namespace = new_namespace = old_namespace[0..-4]
      else
        app.namespace = new_namespace = old_namespace + "new"
      end
      old_hostname = app.hostname
      app.hostname = "#{app.name}-#{new_namespace}.#{$domain}"
      old_repo = app.repo
      app.repo = "#{$temp}/#{new_namespace}_#{app.name}_repo"
      FileUtils.mv old_repo, app.repo
      
      if run("grep '#{old_hostname}' #{app.repo}/.git/config") == 0
        run("sed -i 's,#{old_hostname},#{app.hostname},g' #{app.repo}/.git/config")
      end
      
      if run("grep '#{app.name}-#{old_namespace}.#{$domain}' /etc/hosts") == 0
        run("sed -i 's,#{app.name}-#{old_namespace}.#{$domain},#{app.name}-#{new_namespace}.#{$domain},g' /etc/hosts")
      end
      old_file = app.file
      app.file = "#{$temp}/#{new_namespace}.json"
      FileUtils.mv old_file, app.file
      time = Benchmark.realtime do 
        run("#{$rhc_script} domain update #{old_namespace} #{new_namespace} -l #{app.login} -p #{app.password} -d").should == 0
      end
      log_event "#{time} UPDATE_DOMAIN #{new_namespace} #{app.login}"
      app.persist
    end
  end

  def rhc_snapshot(app)
    rhc_do('rhc_snapshot') do
      app.snapshot="/tmp/#{app.name}-#{app.namespace}.tar.gz"
      FileUtils.rm_rf app.snapshot
      time = Benchmark.realtime do 
        run("#{$rhc_script} snapshot save -l #{app.login} -p #{app.password} --app #{app.name} -f '#{app.snapshot}' -d").should == 0
      end
      log_event "#{time} CREATE_SNAPSHOT #{app.name} #{app.login}"
      app.persist
    end
    output = `ls -l #{app.snapshot}`
    $logger.info("snapshot: #{output}")
  end

  def rhc_restore(app)
    output = `ls -l #{app.snapshot}`
    $logger.info("restore: #{output}")

    rhc_do('rhc_restore') do
      time = Benchmark.realtime do 
        run("#{$rhc_script} snapshot restore -l #{app.login} -p #{app.password} --app #{app.name} -f '#{app.snapshot}' -d").should == 0
      end
      log_event "#{time} RESTORE_SNAPSHOT #{app.name} #{app.login}"
    end
  end

  def rhc_tidy(app)
    rhc_do('rhc_tidy') do
      time = Benchmark.realtime do
        run("#{$rhc_script} app tidy -l #{app.login} -a #{app.name} -p #{app.password} -d").should == 0
      end
      log_event "#{time} TIDY_APP #{app.name} #{app.login}"
    end
  end

  def rhc_create_app(app, use_hosts=true, misc_opts='')
    rhc_sshkey_upload app

    rhc_do('rhc_create_app') do
      cmd = "#{$rhc_script} app create -l #{app.login} -a #{app.name} -r #{app.repo} -t #{app.type} -p #{app.password} #{misc_opts} -d"

      # Short circuit DNS to speed up the tests by adding a host entry and skipping the DNS validation
      if use_hosts
        run("echo '127.0.0.1 #{app.name}-#{app.namespace}.#{$domain}  # Added by cucumber' >> /etc/hosts")
        run("mkdir -m 700 -p ~/.ssh")
        run("test -f ~/.ssh/known_hosts && awk 1 ~/.ssh/known_hosts > ~/.ssh/known_hosts- && mv -f ~/.ssh/known_hosts- ~/.ssh/known_hosts")
        run("ssh-keyscan '#{app.name}-#{app.namespace}.#{$domain}' >> ~/.ssh/known_hosts")
        run("chmod 644 ~/.ssh/known_hosts")
#        cmd << " --no-dns"
      end

      output_buffer = []
      exit_code = 0
      time = Benchmark.realtime do 
        exit_code = run(cmd, output_buffer)
      end
      log_event "#{time} CREATE_APP #{app.name} #{app.type} #{app.login}"

      # Update the application uid from the command output
      begin
        app.update_uid(output_buffer[0])
      rescue NoMethodError
        $logger.debug("Creating the app failed. #{cmd} returned #{output_buffer[0]}")
        raise
      end

      # Update the application creation code
      app.create_app_code = exit_code

      # Persist the app data to filesystem
      app.persist

      return app
    end
  end

  def rhc_embed_add(app, type)
    rhc_do('rhc_embed_add') do
      result = nil
      time = Benchmark.realtime do 
        result = run_stdout("#{$rhc_script} cartridge add -l #{app.login} -a #{app.name} -p #{app.password} -c #{type} -d")
      end
      $logger.info { "Embed #{type} into #{app.inspect}: OUTPUT\n#{result}" }
      log_event "#{time} ADD_EMBED_CART #{app.name} #{type} #{app.login}"
      if type.start_with?('mysql-')
        # Recent versions of rhc now return a connection URL in this format:
        #
        #    mysql://$OPENSHIFT_MYSQL_DB_HOST:$OPENSHIFT_MYSQL_DB_PORT/
        #
        # So, we have to extract the env vars and source them from the gear
        # directory to get the actual values to attach to the app.

        # Source the env var values from the gear directory
        host_val = `source /var/lib/openshift/#{app.uid}/.env/OPENSHIFT_MYSQL_DB_HOST;echo $OPENSHIFT_MYSQL_DB_HOST`.chomp!
        port_val = `source /var/lib/openshift/#{app.uid}/.env/OPENSHIFT_MYSQL_DB_PORT;echo $OPENSHIFT_MYSQL_DB_PORT`.chomp!

        # Assign the hostname ourselves, in host:port format
        app.mysql_hostname = "#{host_val}:#{port_val}"
        app.mysql_user = /^ +Root User: (.*)$/.match(result)[1]
        app.mysql_password = /^ +Root Password: (.*)$/.match(result)[1]
        app.mysql_database = /^ +Database Name: (.*)$/.match(result)[1]

        app.mysql_hostname.should_not be_nil
        app.mysql_user.should_not be_nil
        app.mysql_password.should_not be_nil
        app.mysql_database.should_not be_nil
      end

      app.embed.push(type)
      app.persist
      return app
    end
  end

  def rhc_embed_remove(app, type)
    rhc_do('rhc_embed_remove') do
      # puts app.name
      time = Benchmark.realtime do 
        run("#{$rhc_script} cartridge remove -l #{app.login} -a #{app.name} -p #{app.password} -c #{type} -d").should == 0
      end
      log_event "#{time} REMOVE_EMBED_CART #{app.name} #{type} #{app.login}"
      app.mysql_hostname = nil
      app.mysql_user = nil
      app.mysql_password = nil
      app.mysql_database = nil
      app.embed.delete(type)
      app.persist
      return app
    end
  end

  def rhc_ctl_stop(app)
    rhc_do('rhc_ctl_stop') do
      time = Benchmark.realtime do 
        run("#{$rhc_script} app stop -l #{app.login} -p #{app.password} #{app.name} -d").should == 0
      end
      log_event "#{time} STOP_APP #{app.name} #{app.login}"
      time = Benchmark.realtime do 
        run("#{$rhc_script} app show -l #{app.login} -p #{app.password} #{app.name} --state | grep '#{app.get_stop_string}'").should == 0
      end
      log_event "#{time} STATUS_APP #{app.name} #{app.login}"
    end
  end

  def rhc_add_alias(app)
    rhc_do('rhc_add_alias') do
      time = Benchmark.realtime do 
        run("#{$rhc_script} alias add -l #{app.login} -p #{app.password} #{app.name} '#{app.name}-#{app.namespace}.#{$alias_domain}' -d").should == 0
      end
      log_event "#{time} ADD_ALIAS #{app.name} #{app.login}"
    end
  end

  def rhc_remove_alias(app)
    rhc_do('rhc_remove_alias') do
      time = Benchmark.realtime do 
        run("#{$rhc_script} alias remove -l #{app.login} -p #{app.password} #{app.name} '#{app.name}-#{app.namespace}.#{$alias_domain}' -d").should == 0
      end
      log_event "#{time} REMOVE_ALIAS #{app.name} #{app.login}"
    end
  end

  def rhc_ctl_start(app)
    rhc_do('rhc_ctl_start') do
      time = Benchmark.realtime do 
        run("#{$rhc_script} app start -l #{app.login} -p #{app.password} #{app.name} -d").should == 0
      end
      log_event "#{time} START_APP #{app.name} #{app.login}"
      time = Benchmark.realtime do 
        run("#{$rhc_script} app show -l #{app.login} -p #{app.password} #{app.name} --state | grep '#{app.get_stop_string}'").should == 1
      end
      log_event "#{time} STATUS_APP #{app.name} #{app.login}"
    end
  end

  def rhc_ctl_restart(app)
    rhc_do('rhc_ctl_restart') do
      time = Benchmark.realtime do 
        run("#{$rhc_script} app restart -l #{app.login} -p #{app.password} #{app.name} -d").should == 0
      end
      log_event "#{time} RESTART_APP #{app.name} #{app.login}"
      time = Benchmark.realtime do 
        run("#{$rhc_script} app show -l #{app.login} -p #{app.password} #{app.name} --state | grep '#{app.get_stop_string}'").should == 1
      end
      log_event "#{time} STATUS_APP #{app.name} #{app.login}"
    end
  end

  def rhc_ctl_destroy(app, use_hosts=true)
    rhc_do('rhc_ctl_destroy') do
      time = Benchmark.realtime do 
        run("#{$rhc_script} app delete -l #{app.login} -p #{app.password} #{app.name} --confirm -d").should == 0
      end
      log_event "#{time} DESTROY_APP #{app.name} #{app.login}"
      time = Benchmark.realtime do 
        run("#{$rhc_script} app show -l #{app.login} -p #{app.password} #{app.name} --state | grep 'does not exist'").should == 0
      end
      log_event "#{time} STATUS_APP #{app.name} #{app.login}"
      run("sed -i '/#{app.name}-#{app.namespace}.#{$domain}/d' /etc/hosts") if use_hosts
      FileUtils.rm_rf app.repo
      FileUtils.rm_rf app.file
    end
  end

  def rhc_setup
    run('mkdir -p ~/.openshift')
    run('touch ~/.openshift/express.conf')
  end

  def rhc_do(method, retries=2)
    rhc_setup
    i = 0
    while true
      begin
        yield
        break
      rescue Exception => e
        raise if i >= retries
        $logger.debug "Retrying #{method} after exception caught: #{e.message}"
        i += 1
      end
    end
  end

  #
  # useful methods to avoid duplicating effort
  #

  #
  # Count the number of processes owned by account with cmd_name
  #
  def num_procs acct_name, cmd_name, label=nil
    ps_pattern = /^\s*(\d+)\s+(\S+)\s+(.*)/
    command = "ps --no-headers -o pid,comm,args -u #{acct_name}"
    $logger.debug("num_procs: executing #{command}")

    stdin, stdout, stderr = Open3.popen3(command)

    stdin.close
    outstrings = stdout.readlines
    errstrings = stderr.readlines

    $logger.debug("looking for #{cmd_name}")
    $logger.debug("ps output:\n" + outstrings.join(""))

    proclist = outstrings.collect { |line|
      match = line.match(ps_pattern)

      next if match.nil?

      pid = match[1]
      command = match[2]
      args = match[3]

      command_matches = (command == cmd_name || command.end_with?("/#{cmd_name}"))
      label_matches = (label.nil? || args.match(label))

      if command_matches and label_matches
        pid
      end
    }.compact

    found = proclist ? proclist.size : 0

    if (label)
      $logger.debug("Found = #{found} instances of #{cmd_name} with args matching #{label}")
    else 
      $logger.debug("Found = #{found} instances of #{cmd_name}")
    end

    found
  end

  #
  # Count the number of processes owned by account that match the regex
  #
  def num_procs_like acct_name, regex
    command = "ps --no-headers -f -u #{acct_name}"
    $logger.debug("num_procs: executing #{command}")

    stdin, stdout, stderr = Open3.popen3(command)

    stdin.close

    outstrings = stdout.readlines
    errstrings = stderr.readlines
    $logger.debug("looking for #{regex}")
    $logger.debug("ps output:\n" + outstrings.join(""))

    proclist = outstrings.collect { |line|
      line.match(regex)
    }.compact!

    found = proclist ? proclist.size : 0
    $logger.debug("Found = #{found} instances of #{regex}")
    found
  end
end

World(CommandHelper)
