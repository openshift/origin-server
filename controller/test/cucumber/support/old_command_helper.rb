require 'timeout'
require 'fileutils'
require 'open3'

module OldCommandHelper
  def rhc_create_domain_old(app)
    rhc_do('rhc_create_domain_old') do
      exit_code = run("#{$create_domain_script} -n #{app.namespace} -l #{app.login} -p #{app.password} -d")
      app.create_domain_code = exit_code
      return exit_code == 0
    end
  end

  def rhc_update_namespace_old(app)
    rhc_do('rhc_update_namespace_old') do
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
      `sed -i "s,#{old_hostname},#{new_namespace},g" #{app.repo}/.git/config`
      if run("grep '#{app.name}-#{old_namespace}.#{$domain}' /etc/hosts") == 0
        run("sed -i 's,#{app.name}-#{old_namespace}.#{$domain},#{app.name}-#{new_namespace}.#{$domain},g' /etc/hosts")
      end
      old_file = app.file
      app.file = "#{$temp}/#{new_namespace}.json"
      FileUtils.mv old_file, app.file
      run("#{$create_domain_script} -n #{new_namespace} -l #{app.login} -p #{app.password} --alter -d").should == 0
      app.persist
    end
  end

  def rhc_snapshot_old(app)
    rhc_do('rhc_snapshot_old') do
      app.snapshot="/tmp/#{app.name}-#{app.namespace}.tar.gz"
      FileUtils.rm_rf app.snapshot
      run("#{$snapshot_script} -l #{app.login} -a #{app.name} -s '#{app.snapshot}' -p #{app.password} -d").should == 0
      app.persist
    end
  end
  
  def rhc_restore_old(app)
    rhc_do('rhc_restore_old') do
      run("#{$snapshot_script} -l #{app.login} -a #{app.name} -r '#{app.snapshot}' -p #{app.password} -d").should == 0
    end
  end
  
  def rhc_tidy_old(app)
    rhc_do('rhc_tidy_old') do
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -c tidy -p #{app.password} -d").should == 0
    end
  end

  def rhc_create_app_old(app, use_hosts=true)
    rhc_do('rhc_create_app_old') do
      cmd = "#{$create_app_script} -l #{app.login} -a #{app.name} -r #{app.repo} -t #{app.type} -p #{app.password} -d"

      # Short circuit DNS to speed up the tests by adding a host entry and skipping the DNS validation
      if use_hosts
        run("echo '127.0.0.1 #{app.name}-#{app.namespace}.#{$domain}  # Added by cucumber' >> /etc/hosts")
        run("mkdir -m 700 -p ~/.ssh")
        run("test -f ~/.ssh/known_hosts && awk 1 ~/.ssh/known_hosts > ~/.ssh/known_hosts- && mv -f ~/.ssh/known_hosts- ~/.ssh/known_hosts")
        run("ssh-keyscan '#{app.name}-#{app.namespace}.#{$domain}' >> ~/.ssh/known_hosts")
        run("chmod 644 ~/.ssh/known_hosts")
        cmd << " --no-dns"
      end

      output_buffer = []
      exit_code = run(cmd, output_buffer)

      # Update the application uid from the command output
      app.update_uid(output_buffer[0])
      
      # Update the application creation code
      app.create_app_code = exit_code

      return app
    end
  end

  def rhc_embed_add_old(app, type)
    rhc_do('rhc_embed_add_old') do
      result = run_stdout("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -e add-#{type} -d")
      if type.start_with?('mysql-')
        app.mysql_hostname = /^Connection URL: mysql:\/\/(.*)\/$/.match(result)[1]
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

  def rhc_embed_remove_old(app, type)
    rhc_do('rhc_embed_remove_old') do
      # puts app.name
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -e remove-#{app.embed} -d").should == 0
      app.mysql_hostname = nil
      app.mysql_user = nil
      app.mysql_password = nil
      app.mysql_database = nil
      app.embed.delete(type)
      app.persist
      return app
    end
  end

  def rhc_ctl_stop_old(app)
    rhc_do('rhc_ctl_stop_old') do
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c stop -d").should == 0
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c status | grep '#{app.get_stop_string}'").should == 0
    end
  end

  def rhc_add_alias_old(app)
    rhc_do('rhc_add_alias_old') do
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c add-alias --alias '#{app.name}-#{app.namespace}.#{$alias_domain}' -d").should == 0
    end
  end

  def rhc_remove_alias_old(app)
    rhc_do('rhc_remove_alias_old') do
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c remove-alias --alias '#{app.name}-#{app.namespace}.#{$alias_domain}' -d").should == 0
    end
  end

  def rhc_ctl_start_old(app)
    rhc_do('rhc_ctl_start_old') do
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c start -d").should == 0
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c status | grep '#{app.get_stop_string}'").should == 1
    end
  end

  def rhc_ctl_restart_old(app)
    rhc_do('rhc_ctl_restart_old') do
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c restart -d").should == 0
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c status | grep '#{app.get_stop_string}'").should == 1
    end
  end

  def rhc_ctl_destroy_old(app, use_hosts=true)
    rhc_do('rhc_ctl_destroy_old') do
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c destroy -b -d").should == 0
      run("#{$ctl_app_script} -l #{app.login} -a #{app.name} -p #{app.password} -c status | grep 'does not exist'").should == 0
      run("sed -i '/#{app.name}-#{app.namespace}.#{$domain}/d' /etc/hosts") if use_hosts
      FileUtils.rm_rf app.repo
      FileUtils.rm_rf app.file
    end
  end

end

World(OldCommandHelper)
