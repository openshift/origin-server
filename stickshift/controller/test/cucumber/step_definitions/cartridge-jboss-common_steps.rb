

Then /^the jboss application directory tree will( not)? be populated$/ do |negate|
  cart_instance_root = "#{$home_root}/#{@gear.uuid}/#{@cart.name}"

  file_list =  ['repo', 'run', 'tmp', 'data', @cart.name, 
                "#{@cart.name}/bin",  
                "#{@cart.name}/standalone/configuration"
               ]

  file_list.each do |file_name| 
    file_path = cart_instance_root + "/" + file_name
    $logger.info("Checking for app file at #{file_path}")
    file_exists = File.exists? file_path
    unless negate
      file_exists.should be_true "file #{file_path} does not exist"
    else
      file_exists.should be_false "file #{file_path} exists, and should not"
    end
  end
end


Then /^the jboss server and module files will( not)? exist$/ do |negate|
  cart_instance_dir = "#{$home_root}/#{@gear.uuid}/#{@cart.name}"
  jboss_root = cart_instance_dir + "/" + @cart.name

  file_list = [ "#{jboss_root}/jboss-modules.jar", "#{jboss_root}/modules" ]

  file_list.each do |file_name|
    $logger.info("Checking for server file at #{file_name}")
    file_exists = File.exists? file_name
    unless negate
      file_exists.should be_true "file #{file_name} should exist and does not"
      file_link = File.symlink? file_name
      file_link.should be_true "file #{file_name} should be a symlink and is not"
    else
      file_exists.should be_false "file #{file_name} should not exist and does"
    end
  end
end



Then /^the jboss server configuration files will( not)? exist$/ do |negate|
  cart_instance_dir = "#{$home_root}/#{@gear.uuid}/#{@cart.name}"
  jboss_root = cart_instance_dir + "/" + @cart.name
  jboss_conf_dir = jboss_root + "/standalone/configuration"
  file_list = ["#{jboss_conf_dir}/standalone.xml", 
               "#{jboss_conf_dir}/logging.properties"
             ]

  file_list.each do |file_name|
    $logger.info("Checking for server config file at #{file_name}")
    file_exists = File.exists? file_name
    unless negate
      file_exists.should be_true "file #{file_name} should exist and does not"
    else
      file_exists.should be_false "file #{file_name} should not exist and does"
    end
  end
end


Then /^the jboss standalone scripts will( not)? exist$/ do |negate|
  cart_instance_dir = "#{$home_root}/#{@gear.uuid}/#{@cart.name}"
  jboss_root = cart_instance_dir + "/" + @cart.name

  jboss_bin_dir = jboss_root + "/bin"
  file_name = "#{jboss_bin_dir}/standalone.sh"

  $logger.info("Checking for server script at #{file_name}")
  file_exists = File.exists? file_name
  unless negate
    file_exists.should be_true "file #{file_name} should exist and does not"
  else
    file_exists.should be_false "file #{file_name} should not exist and does"
  end
end



Then /^the jboss git hooks will( not)? exist$/ do |negate|
  git_root = "#{$home_root}/#{@gear.uuid}/git/#{@app.name}.git"
  git_hook_dir = git_root + "/" + "hooks"
  hook_list = ["pre-receive", "post-receive"]

  hook_list.each do |file_name|
    file_path = "#{git_hook_dir}/#{file_name}"
    $logger.info("Checking for git hook at #{file_path}")
    file_exists = File.exists? file_path
    unless negate
      file_exists.should be_true "file #{file_path} should exist and does not"
      file_exec = File.executable? file_path
      file_exec.should be_true "file #{file_path} should be executable and is not"
    else
      file_exists.should be_false "file #{file_path} should not exist and does"
    end
  end
end


Then /^a jboss deployments directory will( not)? exist$/ do |negate|
  cart_instance_dir = "#{$home_root}/#{@gear.uuid}/#{@cart.name}"
  jboss_root = cart_instance_dir + "/" + @cart.name

  deploy_root = Dir.new "#{jboss_root}/standalone/deployments"
  
  deploy_contents = ['ROOT.war']

  deploy_contents.each do |file_name|
    $logger.info("Checking for deployment dir file at #{file_name}")
    unless negate
      deploy_root.member?(file_name).should be_true "file #{deploy_root.path}/#{file_name} should exist and does not"
    else
      deploy_root.member?(file_name).should be_false "file #{deploy_root.path}/#{file_name} should not exist and does"
    end
  end
end

Then /^the jboss maven repository will( not)? exist$/ do |negate|
  m2_root = "#{$home_root}/#{@gear.uuid}/.m2"
  $logger.info("Checking for Maven repo at #{m2_root}")
  m2_root_exists = File.exists? m2_root
  unless negate
    m2_root_exists.should be_true "Dir #{m2_root} should exist and does not"
  else
    m2_root_exists.should be_false "Dir #{m2_root} should not exist and does"
  end  
end
