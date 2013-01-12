require 'rubygems'
require 'fileutils'
require 'json'
require 'logger'
require 'open4'
require 'pp'
require 'rest-client'

include AppHelper

When /^I configure a hello_world diy application with jenkins enabled$/ do
    @app = TestApp.create_unique('diy-0.1', 'diy')
    run "echo -e \"Host #{@app.hostname}\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"

    register_user(@app.login, @app.password) if $registration_required
    if rhc_create_domain(@app)
      @diy_app = rhc_create_app(@app, false, '--enable-jenkins --timeout=300')
      @diy_app.create_app_code.should be == 0
    else
      raise "Failed to create domain: #{@app}"
    end

    @app.update_jenkins_info

    response = `#{@app.jenkins_build}`
    $logger.debug "@jenkins_build response = [#{response}]"

    job = JSON.parse(response)

    job.should_not be_nil
    job['name'].should be == 'diy-build', "#{job['name']} not equal to diy-build"
    job['color'].should be == 'grey', "job #{job['name']} has already been run."
end

When /^I push an update to the diy application$/ do
    output = `awk <#{$temp}/cucumber.log '/^ *Git URL.*diy.git.$/ {print $NF}'`.split("\n")
    @diy_git_url = output[-1]
    $logger.debug "git url: #{@diy_git_url}"
    assert_not_nil @diy_git_url, "Failed to find Git URL for diy application"

    FileUtils.rm_rf 'diy' if File.exists? 'diy'
    assert_directory_not_exists 'diy'

    exit_code = run "git clone #{@diy_git_url} diy"
    assert_equal 0, exit_code, "Failed to clone diy repo"

    Dir.chdir("diy") do
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

Then /^the application will be updated$/ do
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
    
    app_uuid = @diy_git_url.match(TestApp::SSH_OUTPUT_PATTERN)[1]
    path = "/var/lib/openshift/#{app_uuid}/app-root/repo/#{@app.name}/index.html"
    $logger.debug "jenkins built application path = #{path}"
    `grep 'Jenkins Builder Testing' "#{path}"`
    $?.to_i.should be == 0
end

Then /^I deconfigure the diy application with jenkins enabled$/ do
    rhc_ctl_destroy(@app, false)
    @app.name='jenkins'
    rhc_ctl_destroy(@app, false)
end
