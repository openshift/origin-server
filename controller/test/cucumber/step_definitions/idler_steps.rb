# match against oo-idle and oo-restore to avoid conflict
When /^I oo-(idle|restore) the application$/ do |action|
  cmd = nil

  case action
    when "idle"
      cmd = "/usr/sbin/oo-idler -u #{@gear.uuid}" 
    when "restore"
      cmd = "/usr/sbin/oo-restorer -u #{@gear.uuid}"
  end

  exit_code = run cmd
  assert_equal 0, exit_code, "Failed to #{action} application running #{cmd}"
end

Then /^I record the active capacity( after idling)?$/ do |negate|
  @active_capacity = `facter active_capacity`.to_f

  if (negate)
    # active capacity may be 0.0 after idling.
    @active_capacity.should be >= 0.0
  else 
    @active_capacity.should be > 0.0
  end 
end

Then /^the active capacity has been (reduced|increased)$/ do |change|
  current_capacity = `facter active_capacity`.to_f
  current_capacity.should be >= 0.0

  case change
    when "reduced"
      @active_capacity.should be > current_capacity
    when "increased"
      @active_capacity.should be < current_capacity
  end
end
