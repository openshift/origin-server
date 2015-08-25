include AppHelper

Given /^a new user with login "([^\"]*)" and (?:domain|namespace) "([^\"]*)"$/ do |login, namespace|
    @unique_namespace_apps_hash ||= {}
    register_user(login, "xyz123") if $registration_required
    empty_app = AppHelper::TestApp.new(namespace, login, nil, nil, "xyz123", nil)
    rhc_create_domain(empty_app)
    raise "Could not create domain: #{empty_app.create_domain_code}" unless empty_app.create_domain_code == 0
    @unique_namespace_apps_hash[namespace] = empty_app
end

When /^the (?:user|member) "([^\"]*)" is added to the (?:domain|namespace) "([^\"]*)"$/ do |new_member, namespace|
    app_login = get_app_login_from_namespace(namespace)
    command = "oo-admin-ctl-domain -l \"#{app_login}\" -n #{namespace} -c add_member -m #{new_member}"
    $logger.info("Executing the command: #{command}")
    output_buffer = []
    exit_code = run(command, output_buffer)
    raise "Failed to add member #{new_member} to namespace #{namespace}. Exit code: #{exit_code} and output message: #{output_buffer}" if exit_code != 0
end

When /^the (?:user|member) "([^\"]*)" is removed from the (?:domain|namespace) "([^\"]*)"$/ do |removed_member, namespace|
    app_login = get_app_login_from_namespace(namespace)
    command = "oo-admin-ctl-domain -l \"#{app_login}\" -n #{namespace} -c remove_member -m #{removed_member}"
    $logger.info("Executing the command: #{command}")
    output_buffer = []
    exit_code = run(command, output_buffer)
    raise "Failed to remove member #{new_member} from namespace #{namespace}. Exit code: #{exit_code} and output message: #{output_buffer}" if exit_code != 0
end

Then /^the (?:user|member) "([^\"]*)" is a member of the (?:domain|namespace) "([^\"]*)"$/ do |member, namespace|
    app_login = get_app_login_from_namespace(namespace)
    command = "oo-admin-ctl-domain -l \"#{app_login}\" -n #{namespace} -c list_members"
    $logger.info("Executing the command: #{command}")
    output_buffer = []
    exit_code = run(command, output_buffer)
    raise "Failed to list members of namespace #{namespace}. Exit code: #{exit_code} and output message: #{output_buffer}" if exit_code != 0
    output_buffer[0].split("\n")[1].should == "#{app_login}(admin), #{member}(admin)"
end

Then /^the (?:user|member) "([^\"]*)" is not a member of the (?:domain|namespace) "([^\"]*)"$/ do |member, namespace|
    app_login = get_app_login_from_namespace(namespace)
    command = "oo-admin-ctl-domain -l \"#{app_login}\" -n #{namespace} -c list_members"
    $logger.info("Executing the command: #{command}")
    output_buffer = []
    exit_code = run(command, output_buffer)
    raise "Failed to list members of namespace #{namespace}. Exit code: #{exit_code} and output message: #{output_buffer}" if exit_code != 0
    output_buffer[0].split("\n")[1].should == "#{app_login}(admin)"
end

When /^the "([^\"]*)" (?:user|member)'s role is modified to "([^\"]*)" in the namespace "([^\"]*)"$/ do |member, role, namespace|
    app_login = get_app_login_from_namespace(namespace)
    command = "oo-admin-ctl-domain -l \"#{app_login}\" -n #{namespace} -c update_member -m #{member} -r #{role}"
    $logger.info("Executing the command: #{command}")
    output_buffer = []
    exit_code = run(command, output_buffer)
    raise "Failed to list members of namespace #{namespace}. Exit code: #{exit_code} and output message: #{output_buffer}" if exit_code != 0
end

Then /^the (?:user|member) "([^\"]*)" has the role "([^\"]*)" in the (?:namespace|domain) "([^\"]*)"$/ do |member, role, namespace|
    app_login = get_app_login_from_namespace(namespace)
    command = "oo-admin-ctl-domain -l \"#{app_login}\" -n #{namespace} -c list_members"
    $logger.info("Executing the command: #{command}")
    output_buffer = []
    exit_code = run(command, output_buffer)
    raise "Failed to list members of namespace #{namespace}. Exit code: #{exit_code} and output message: #{output_buffer}" if exit_code != 0
    output_buffer[0].split("\n")[1].should == "#{app_login}(admin), #{member}(edit)"
end

def get_app_login_from_namespace(namespace)
  app = @unique_namespace_apps_hash[namespace]
  raise "Could not find existing namepsace #{namespace}" unless app
  app.login
end
