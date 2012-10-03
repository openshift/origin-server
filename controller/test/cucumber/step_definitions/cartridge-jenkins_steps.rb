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
      @diy_app = rhc_create_app(@app, false, '--enable-jenkins --timeout=120')
      @diy_app.create_app_code.should be == 0
    else
      raise "Failed to create domain: #{@app}"
    end

    output = `awk <#{$temp}/cucumber.log '/^Job URL: / {print $3} /^Jenkins /,/^Note: / {if ($0 ~ /^ *User: /) print $2; if ($0 ~ /^ *Password: /) print $2;}'`.split("\n")
    jenkins_user = output[-3]
    jenkins_user.should_not be_nil

    jenkins_password = output[-2]
    jenkins_password.should_not be_nil

    jenkins_url = output[-1]
    jenkins_url.should_not be_nil

    $logger.debug "jenkins_url = #{jenkins_url}\njenkins_user = #{jenkins_user}\njenkins_password = #{jenkins_password}"

    @jenkins_build = "curl -ksS -X GET #{jenkins_url}api/json --user '#{jenkins_user}:#{jenkins_password}'"
    $logger.debug "@jenkins_build = #{@jenkins_build}"

    response = `#{@jenkins_build}`
    $logger.debug "@jenkins_build response = [#{response}]"

    job = JSON.parse(response)

    job.should_not be_nil
    job['name'].should be == 'diy-build', "#{job['name']} not equal to diy-build"
    job['color'].should be == 'grey', "job #{job['name']} has already been run."
end

When /^I push an update to the diy application$/ do
    output = `awk <#{$temp}/cucumber.log '/^ *Git URL:.*diy.git.$/ {print $3}'`.split("\n")
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
        response = `#{@jenkins_build}`
        $logger.debug "@jenkins_build response = #{response}"

        job = JSON.parse(response)
      end while job['color'] != 'blue'
    end
    job['color'].should be == 'blue' 
    
    app_uuid = @diy_git_url.match(TestApp::SSH_OUTPUT_PATTERN)[1]
    path = "/var/lib/openshift/#{app_uuid}/app-root/repo/#{@app.name}/index.html"
    $logger.debug "jenkins built application path = #{path}"
    `grep 'Jenkins Builder Testing' "#{path}"`
    $?.to_s.should be == "0"
end

Then /^I deconfigure the diy application with jenkins enabled$/ do
    rhc_ctl_destroy(@app, false)
end
