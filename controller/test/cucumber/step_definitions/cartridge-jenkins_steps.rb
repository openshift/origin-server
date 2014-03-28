require 'rubygems'
require 'fileutils'
require 'json'
require 'logger'
require 'open4'
require 'pp'
require 'rest-client'

include AppHelper

When /^I configure a hello_world (.*?) application with jenkins enabled$/ do |app_type|
    @app = TestApp.create_unique(app_type, 'myapp')
    run "echo -e \"Host #{@app.hostname}\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"

    register_user(@app.login, @app.password) if $registration_required
    if rhc_create_domain(@app)
      @my_app = rhc_create_app(@app, false, '--enable-jenkins --timeout=300')
      @my_app.create_app_code.should be == 0
    else
      raise "Failed to create domain: #{@app}"
    end

    @app.update_jenkins_info

    response = `#{@app.jenkins_build}`
    $logger.debug "@jenkins_build response = [#{response}]"

    job = JSON.parse(response)

    job.should_not be_nil
    job['name'].should be == 'myapp-build', "#{job['name']} not equal to myapp-build"
    assert (job['color'] == 'grey' or job['color'] == 'notbuilt'), "job #{job['name']} has already been run."
end

When /^I push an update to the diy application$/ do
    output = `awk <#{$temp}/cucumber.log '/^ *Git remote.*myapp.git.$/ {print $NF}'`.split("\n")
    @myapp_git_url = output[-1]
    $logger.debug "git url: #{@myapp_git_url}"
    assert_not_nil @myapp_git_url, "Failed to find Git URL for diy application"


    git_dir = "/tmp/rhc/myapp_jenkins"
    FileUtils.rm_rf git_dir if File.exists? git_dir
    refute_directory_exist git_dir

    exit_code = run "git clone #{@myapp_git_url} #{git_dir}"
    assert_equal 0, exit_code, "Failed to clone myapp repo"

    Dir.chdir(git_dir) do
      exit_code = run "sed -i 's/Welcome to OpenShift/Jenkins Builder Testing/' diy/index.html"
      assert_equal 0, exit_code, "Failed to update diy/index.html"

      exit_code = run "git commit -a -m 'force build'"
      assert_equal 0, exit_code, "Failed to commit update to diy/index.html"

      exit_code = -1
      begin
        Timeout::timeout(300) do
          exit_code = run "git push"
        end
      rescue Timeout::Error
        $logger.warn "Timed out during git push. Usually means jenkins cartridge failing"
        raise
      rescue => e
        $logger.error "Unexpected exception #{e.class} during git push: #{e.message}\n#{e.backtrace.join("\n")}"
        raise
      end
      assert_equal 0, exit_code, "Failed to push update to diy/index.html"
    end
end

When /^I push an update to the Go application$/ do
    output = `awk <#{$temp}/cucumber.log '/^ *Git remote.*myapp.git.$/ {print $NF}'`.split("\n")
    @myapp_git_url = output[-1]
    $logger.debug "git url: #{@myapp_git_url}"
    assert_not_nil @myapp_git_url, "Failed to find Git URL for Go application"


    git_dir = "/tmp/rhc/myapp_jenkins"
    FileUtils.rm_rf git_dir if File.exists? git_dir
    refute_directory_exist git_dir

    exit_code = run "git clone #{@myapp_git_url} #{git_dir}"
    assert_equal 0, exit_code, "Failed to clone myapp repo"

    Dir.chdir(git_dir) do
      exit_code = run "sed -i 's/hello, world/Jenkins Builder Testing/' web.go"
      assert_equal 0, exit_code, "Failed to update web.go"

      exit_code = run "git commit -a -m 'force build'"
      assert_equal 0, exit_code, "Failed to commit update to web.go"

      exit_code = -1
      begin
        Timeout::timeout(300) do
          exit_code = run "git push"
        end
      rescue Timeout::Error
        $logger.warn "Timed out during git push. Usually means jenkins cartridge failing"
        raise
      rescue => e
        $logger.error "Unexpected exception #{e.class} during git push: #{e.message}\n#{e.backtrace.join("\n")}"
        raise
      end
      assert_equal 0, exit_code, "Failed to push update to diy/index.html"
    end
end

Then /^the diy application will be updated$/ do
    # wait for ball to change blue...
    job = {'color' => 'purple'}
    OpenShift::timeout(300) do
      begin
        sleep 1
        response = `#{@app.jenkins_build}`
        $logger.debug "@jenkins_build response = #{response}"

        job = JSON.parse(response)
      rescue => e
        $logger.warn "Unexpected exception checking update: #{e.message}\n#{e.backtrace.join("\n")}"
      end while job['color'] != 'blue'
    end
    job['color'].should be == 'blue' 

    app_uuid = @myapp_git_url.match(TestApp::SSH_OUTPUT_PATTERN)[1]
    path = "/var/lib/openshift/#{app_uuid}/app-root/repo/diy/index.html"
    $logger.debug "jenkins built application path = #{path}"
    `grep 'Jenkins Builder Testing' "#{path}"`
    $?.to_i.should be == 0
end

Then /^the Go application will be updated$/ do
    # wait for ball to change blue...
    job = {'color' => 'purple'}
    OpenShift::timeout(300) do
      begin
        sleep 1
        response = `#{@app.jenkins_build}`
        $logger.debug "@jenkins_build response = #{response}"

        job = JSON.parse(response)
      rescue => e
        $logger.warn "Unexpected exception checking update: #{e.message}\n#{e.backtrace.join("\n")}"
      end while job['color'] != 'blue'
    end
    job['color'].should be == 'blue' 

    app_uuid = @myapp_git_url.match(TestApp::SSH_OUTPUT_PATTERN)[1]
    path = "/var/lib/openshift/#{app_uuid}/app-root/repo/web.go"
    $logger.debug "jenkins built application path = #{path}"
    `grep 'Jenkins Builder Testing' "#{path}"`
    $?.to_i.should be == 0
end

Then /^I deconfigure the application with jenkins enabled$/ do
    rhc_ctl_destroy(@app, false)
    @app.name='jenkins'
    rhc_ctl_destroy(@app, false)
end
