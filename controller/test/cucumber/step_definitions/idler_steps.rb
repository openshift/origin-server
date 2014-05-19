Given /^a new ([^ ]+) application with ([^ ]+) process, verify that it can be auto-restored after idling$/ do |cart_name, proc_name|
  steps %{
    Given a new client created #{cart_name} application
    Then a #{proc_name} process will be running
    And I record the active capacity

    When I oo-idle the application
    Then a #{proc_name} process will not be running
    And the active capacity has been reduced
    And I record the active capacity after idling

    When I run the health-check for the <type> cartridge
    Then a #{proc_name} process will be running
    And the active capacity has been increased
  }
end

# match against oo-idle and oo-restore to avoid conflict
When /^I oo-(idle|restore) the application$/ do |action|
  cmd = nil

  uuid = current_test_app_uuid

  case action
    when "idle"
      cmd = "/usr/sbin/oo-admin-ctl-gears idlegear #{uuid}"
    when "restore"
      cmd = "/usr/sbin/oo-restorer -u #{uuid}"
  end

  exit_code = run cmd
  assert_equal 0, exit_code, "Failed to #{action} application running #{cmd}"
end

Then /^I record the active capacity( after idling)?$/ do |negate|
  @active_capacity = `facter active_capacity`.split("\n").last.to_f

  if (negate)
    # active capacity may be 0.0 after idling.
    @active_capacity.should be >= 0.0
  else 
    @active_capacity.should be > 0.0
  end 
end

Then /^the active capacity has been (reduced|increased)$/ do |change|
  current_capacity = `facter active_capacity`.split("\n").last.to_f
  current_capacity.should be >= 0.0

  case change
    when "reduced"
      @active_capacity.should be > current_capacity
    when "increased"
      @active_capacity.should be < current_capacity
  end
end
