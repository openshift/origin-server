Then /^the app is( not)? returned when fetching all gears using broker key auth$/ do |negate|
  found_uids = oo_admin_broker_auth_find_gears
  asserted_uids = @apps.map {|a| a.uid}

  if (found_uids & asserted_uids) == asserted_uids
    negate ? fail : pass
  end
end
