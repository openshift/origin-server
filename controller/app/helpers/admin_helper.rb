module AdminHelper

  $premium_carts = []

  $datastore_hash = {}
  $gear_uid_hash = {}
  $district_hash = {}

  $user_hash = {}
  $domain_hash = {}
  $app_gear_hash = {}
  $domain_gear_sizes = []
  $user_gear_sizes = []

  $usage_gear_hash = {}
  $usage_storage_hash = {}
  $usage_cart_hash = {}

  $chk_gear_mongo_node = false
  $chk_app = false
  $chk_usage = false
  $chk_district = false

  $summary = []
  $summary_count = 0
  $total_errors = 0
  $verbose = false
  $invalid_plan = false

  $billing_enabled = Rails.configuration.respond_to?('billing')
  $districts_enabled = Rails.configuration.msg_broker[:districts][:enabled]
  $first_district_uid = Rails.configuration.msg_broker[:districts][:first_uid]

  def to_b
    return true if self.to_s.strip =~ /^(true|t|yes|y|1)$/i
    return false
  end

  def run(method, *args)
    ret = nil
    begin
      if args.length > 0
        ret = send(method, *args)
      else
        ret = send(method)
      end
    rescue Exception => e
      $total_errors += 1
      puts e.message
      puts e.backtrace.inspect
    end
    ret
  end

  def print_message(msg, flush=false)
    $total_errors += 1
    $summary_count += 1
    $summary << msg
    if $summary_count > 128 or flush
      puts $summary.join("\n")
      $summary = []
      $summary_count = 0
    end
  end

  def get_premium_carts
    return $premium_carts unless $premium_carts.empty?

    CartridgeType.active.each do |cart|
      $premium_carts.push(cart.name) if cart.is_premium?
    end
    return $premium_carts
  end

  def datastore_has_gear_uid?(gear_uid, server_identity_list)
    query = {"gears" => {"$elemMatch" => { "uid" => gear_uid, "server_identity" => {"$in" => server_identity_list}}}}
    return Application.where(query).exists?
  end

  def district_has_available_uid?(district_uuid, gear_uid)
    query = { "uuid" => district_uuid, "available_uids" => gear_uid }
    return District.where(query).exists?
  end

  def check_consumed_gears(user)
    begin
      actual_gears = 0
      user.domains.each do |d|
        d.applications.each {|a| actual_gears += a.gears.length}
      end
      return user.consumed_gears, actual_gears
    rescue Mongoid::Errors::DocumentNotFound
      print_message "Error: User with ID #{user_id} not found in mongo"
      return 0, 0
    end
  end

  def get_user_info(user)
    user_ssh_keys = []
    user["ssh_keys"].each { |k| user_ssh_keys << ["#{user['_id'].to_s}-#{k['name']}", Digest::MD5.hexdigest(k["content"]), nil] if k["content"] } if user["ssh_keys"].present?
    user_caps = user["capabilities"]
    if user["plan_id"]
      plans = OpenShift::BillingService.instance.get_plans
      if plans.present?
        plan_caps = plans[user["plan_id"].to_sym][:capabilities]
        user_caps = plan_caps.deep_dup.merge(user_caps)
      else
        $invalid_plan = true
      end
    end
    user_info = {"consumed_gears" => user["consumed_gears"], "domains" => {}, "login" => user["login"], "ssh_keys" => user_ssh_keys,
               "max_untracked_addtl_storage_per_gear" => user_caps["max_untracked_addtl_storage_per_gear"],
               "plan_id" => user["plan_id"], "plan_state" => user["plan_state"], "usage_account_id" => user["usage_account_id"],
               "parent_user_id" => user["parent_user_id"]}
    user_info
  end

  def get_user_hash(user_id, skip_errors=false)
    unless $user_hash[user_id.to_s]
      populate_user_hash({:read => :primary}, user_id, skip_errors)
    end
    $user_hash[user_id.to_s]
  end

  def populate_user_hash(options=nil, user_id=nil, skip_errors=false)
    options ||= {}
    options.reverse_merge!({:timeout => false})
    query = {}
    query['_id'] = BSON::ObjectId(user_id.to_s) if user_id.present?
    OpenShift::DataStore.find(:cloud_users, query, options) do |user|
      unless user["login"].present?
        print_message "User with Id #{user['_id']} has a null, empty, or missing login." unless skip_errors
      else
        $user_hash[user["_id"].to_s] = get_user_info(user)
        $user_gear_sizes |= user["capabilities"]["gear_sizes"] if user["capabilities"].present? and user["capabilities"]["gear_sizes"].present?
      end
    end
    # Check for invalid plans from get_user_info
    if $invalid_plan
      puts "Warning: At least one user has a plan id defined, but no plans could be found. Plan-defined user capabilities will not be considered."
    end
  end

  def get_domain_hash(domain_id)
    unless $domain_hash[domain_id.to_s]
      populate_domain_hash({:read => :primary}, domain_id)
    end
    $domain_hash[domain_id.to_s]
  end

  def populate_domain_hash(options=nil, domain_id=nil)
    options ||= {}
    options.reverse_merge!({:timeout => false})
    query = {}
    query['_id'] = BSON::ObjectId(domain_id.to_s) if domain_id.present?
    OpenShift::DataStore.find(:domains, query, options) do |domain|
      owner_id = domain["owner_id"].to_s
      env_vars = {}
      domain["env_vars"].each {|ev| env_vars[ev["key"]] = ev["component_id"].to_s} if domain["env_vars"].present?
      system_ssh_keys = []
      domain["system_ssh_keys"].each { |k| system_ssh_keys << ["domain-#{k['name']}", Digest::MD5.hexdigest(k["content"]), k["component_id"].to_s] if k["content"] } if domain["system_ssh_keys"].present?
      $domain_hash[domain["_id"].to_s] = {"owner_id" => owner_id, "canonical_namespace" => domain["canonical_namespace"], "env_vars" => env_vars, "ssh_keys" => system_ssh_keys, "ref_ids" => []}
      get_user_hash(owner_id, true)
      $domain_gear_sizes |= domain["allowed_gear_sizes"]

      print_message "Domain '#{domain['_id']}' has no members in mongo." unless domain['members'].present?

      if $user_hash[owner_id]
        $user_hash[owner_id]["domains"][domain["_id"].to_s] = 0
      else
        print_message "User '#{owner_id}' for domain '#{domain['_id']}' does not exist in mongo."
      end
    end
  end

  def populate_app_hash(options={})
    app_selection = {:fields => ["name", "created_at", "domain_id", "gears._id", "gears.group_instance_id", "gears.app_dns",
                             "gears.uuid", "gears.uid", "gears.server_identity",
                             "group_overrides.additional_filesystem_gb", "group_overrides.components.cart",
                             "group_instances._id", "component_instances._id", "component_instances.cartridge_name",
                             "component_instances", "app_ssh_keys.name", "app_ssh_keys.content", "app_ssh_keys.component_id",
                             "members", "domain_namespace", "owner_id"],
                     :timeout => false}
    app_query = {"gears.0" => {"$exists" => true}}
    total_gear_count = 0
    options.reverse_merge!(app_selection)
    OpenShift::DataStore.find(:applications, app_query, options) do |app|
      owner_id = nil
      login = nil
      creation_time = app['created_at'].utc
      domain_id = app['domain_id'].to_s
      get_domain_hash(domain_id)
      owner_id = $domain_hash[domain_id]["owner_id"]
      get_user_hash(owner_id, true)
      app_life_time = Time.now.utc - creation_time

      if $chk_app or $chk_gear_mongo_node
        # set the component and gear ids in the $domain_hash to check for stale sshkeys and env variables
        $domain_hash[domain_id]["ref_ids"] |= app["component_instances"].map {|ci_hash| ci_hash["_id"].to_s} if app["component_instances"].present?
        $domain_hash[domain_id]["ref_ids"] |= app["gears"].map {|g_hash| g_hash["_id"].to_s} if app["gears"].present?

        app_ssh_keys = []
        app["app_ssh_keys"].each { |k| app_ssh_keys << [k["name"], Digest::MD5.hexdigest(k["content"]), k["component_id"].to_s] if k["content"] } if app["app_ssh_keys"].present?
        app_ssh_keys |= $domain_hash[domain_id]["ssh_keys"] if $domain_hash[domain_id]["ssh_keys"].present?

        if owner_id.nil?
          print_message "Application '#{app['name']}' does not have a domain '#{domain_id}' in mongo." if app_life_time > 600
        elsif $user_hash[owner_id].nil?
          print_message "Application '#{app['name']}' for domain '#{domain_id}' does not have a user '#{owner_id}' in mongo."
        else
          login = $user_hash[owner_id]["login"]
          app_ssh_keys |= $user_hash[owner_id]["ssh_keys"]

          if app['owner_id'].nil?
            print_message "Application '#{app['name']}' for domain '#{domain_id}' does not have the denormalized owner_id set in mongo."
          elsif app['owner_id'].to_s != owner_id
            print_message "Application '#{app['name']}' for domain '#{domain_id}' has a denormalized owner_id of '#{app['owner_id']}' instead of the correct user '#{owner_id}' in mongo."
          end
        end

        if app['members'].present?
          # add the member ssh keys
          app['members'].each do |m|
            # we are passing the resource as nil for now since we don't have the mongoid object
            # and the resource is ignored for :ssh_to_gears
            if Ability.has_permission?(m["_id"], :ssh_to_gears, Application, m["r"], nil)
              app_ssh_keys |= $user_hash[m["_id"].to_s]["ssh_keys"] unless $user_hash[m["_id"].to_s].nil?
            end
          end
        else
          print_message "Application '#{app['name']}' for domain '#{domain_id}' has no members in mongo."
        end
      end

      gear_count = 0
      has_dns_gear = false
      app['gears'].each do |gear|
        gear_count += 1
        has_dns_gear = true if gear["app_dns"]

        $datastore_hash[gear['uuid'].to_s] = { 'login' => login, 'creation_time' => creation_time, 'gear_uid' => gear['uid'], 'server_identity' => gear['server_identity'], 'app_id' => app['_id'].to_s, 'app_ssh_keys' => app_ssh_keys.deep_dup, 'domain_id' => domain_id } if $chk_app or $chk_gear_mongo_node

        if $districts_enabled and $chk_district
          # record all used uid values for each node to match later with the district
          si = gear['server_identity']
          $gear_uid_hash[si] = [] unless $gear_uid_hash.has_key?(si)
          $gear_uid_hash[si] << gear['uid'].to_i
        end
      end if app['gears'].present?
      total_gear_count += gear_count
      $user_hash[owner_id]["domains"][domain_id] += gear_count if $user_hash[owner_id]

      if $chk_app
        if (gear_count > 0) and !has_dns_gear
          print_message "Application '#{app['name']}' with Id '#{app['_id']}' has DNS gear missing."
        end

        domain_namespace = $domain_hash[domain_id]["canonical_namespace"]
        if app['domain_namespace'].nil?
          print_message "Application '#{app['name']}' for domain '#{domain_id}' does not have the denormalized domain_namespace set in mongo."
        elsif domain_namespace != app['domain_namespace'].to_s
          print_message "Application '#{app['name']}' for domain '#{domain_id}' has a denormalized domain_namespace of '#{app['domain_namespace']}' instead of the correct canonical namespace '#{domain_namespace}' in mongo."
        end

        if app_life_time > 600
          gi_hash = {}
          if app["group_instances"]
            app["group_instances"].each {|gi| gi_hash[gi["_id"].to_s] = false}
          else
            print_message "Application '#{app['name']}' with Id '#{app['_id']}' doesn't have any group instances"
          end

          # check for component instances without corresponding group instances and vice-versa
          if app['component_instances']
            app['component_instances'].each do |ci|
              gid = ci['group_instance_id']
              if gid
                if gi_hash.has_key? gid.to_s
                  gi_hash[gid.to_s] = true
                else
                  print_message "Application '#{app['name']}' with Id '#{app['_id']}' has invalid group instance '#{gid}' for component instance '#{ci['_id']}'."
                end
              else
                print_message "Application '#{app['name']}' with Id '#{app['_id']}' has missing group instance for component instance '#{ci['_id']}'."
              end
            end
            gi_hash.each do |gi_id, present|
              unless present
                print_message "Application '#{app['name']}' with Id '#{app['_id']}' has no components for group instance with Id '#{gi_id}'"
              end
            end
          else
            print_message "Application '#{app['name']}' with Id '#{app['_id']}' doesn't have any component instances"
          end

          # check for applications without any gears in the group instance and vice versa
          # check for application gears with server_identity field not set
          if app["gears"]
            gi_hash.each {|k,v| gi_hash[k] = false}
            app["gears"].each do |gear|
              if gear['server_identity'].blank?
                print_message "Application '#{app['name']}' with Id '#{app['_id']}' for gear '#{gear['_id']}' does not have server_identity set in mongo."
              end
              gid = gear['group_instance_id']
              if gid
                if gi_hash.has_key? gid.to_s
                  gi_hash[gid.to_s] = true
                else
                  print_message "Application '#{app['name']}' with Id '#{app['_id']}' has invalid group instance '#{gid}' for gear '#{gear['_id']}'"
                end
              else
                print_message "Application '#{app['name']}' with Id '#{app['_id']}' has missing group instance for gear '#{gear['_id']}'."
              end
            end
            gi_hash.each do |gi_id, present|
              unless present
                # check if this is a group instance created for an external cartridge
                is_external = begin
                                a = Application.find_by(:_id => app['_id'].to_s)
                                ci = a.component_instances.find_by(:group_instance_id => gi_id.to_s)
                                ci.is_external?
                              rescue Mongoid::Errors::DocumentNotFound
                                false
                              end
                print_message "Application '#{app['name']}' with Id '#{app['_id']}' has no gears for group instance with Id '#{gi_id}'" unless is_external
              end
            end
          else
            print_message "Application '#{app['name']}' with Id '#{app['_id']}' doesn't have any gears."
          end
        end
      end

      if $chk_usage and (!$user_hash[owner_id] or !$user_hash[owner_id]['parent_user_id'])
        gi_hash = {}
        app['group_instances'].each do |gi|
          gid = gi['_id'].to_s
          gi_hash[gid] = {}
          gi_hash[gid]['premium_carts'] = []
          gi_hash[gid]['addtl_fs_gb'] = 0
        end
        # Get premium carts for the group instance
        premium_carts = get_premium_carts
        app['component_instances'].each do |ci|
          if premium_carts.include?(ci['cartridge_name'])
            gid = ci['group_instance_id'].to_s
            gi_hash[gid] = {} unless gi_hash[gid]
            gi_hash[gid]['premium_carts'] = [] unless gi_hash[gid]['premium_carts']
            gi_hash[gid]['premium_carts'] << ci['cartridge_name']
          end
        end
        # Get group instances with additional storage consumption
        user_untracked_storage_limit = 0
        if owner_id and $user_hash[owner_id] and $user_hash[owner_id]["max_untracked_addtl_storage_per_gear"]
          user_untracked_storage_limit = $user_hash[owner_id]["max_untracked_addtl_storage_per_gear"]
        end
        app['group_overrides'].each do |go|
          next if !go['additional_filesystem_gb'] or (go['additional_filesystem_gb'] <= user_untracked_storage_limit)
          go['components'].each do |go_components|
            found = false
            app['component_instances'].each do |ci|
              if ci['cartridge_name'] == go_components['cart']
                gid = ci['group_instance_id'].to_s
                gi_hash[gid] = {} unless gi_hash[gid]
                gi_hash[gid]['addtl_fs_gb'] = (go['additional_filesystem_gb'] - user_untracked_storage_limit)
                found = true
                break
              end
            end
            break if found
          end
        end
        # Generate app_gear_hash
        app['gears'].each do |gear|
          gear_id = gear['_id'].to_s
          unless $app_gear_hash[gear_id]
            gid = gear['group_instance_id'].to_s
            $app_gear_hash[gear_id] = { 'app_id' => app['_id'].to_s, 'app_name' => app['name'], 'addtl_fs_gb' => gi_hash[gid] ? gi_hash[gid]['addtl_fs_gb'] : 0, 'premium_carts' => gi_hash[gid] ? gi_hash[gid]['premium_carts'] : [] }
          else
            app_name = $app_gear_hash[gear_id]['app_name']
            print_message "Gear Id '#{gear['_id']}' for Application '#{app['name']}' is already taken by another Application '#{app_name}'"
          end
        end
      end
    end
    puts "Total gears found in mongo: #{total_gear_count}"
  end

  def populate_district_hash(options={})
    return unless $districts_enabled and $chk_district

    options.reverse_merge!({:timeout => false})
    OpenShift::DataStore.find(:districts, {}, options) do |district|
      si_list = (district["servers"] || []).map {|si| si["name"]}
      si_list.delete_if {|si| si.nil?}
      $district_hash[district["uuid"].to_s] = { 'name' => district["name"], 'max_capacity' => district["max_capacity"], 'server_names' => si_list, 'available_uids' => district["available_uids"] }

      # check available_uids list length and available_capacity
      if district["available_uids"].length != district["available_capacity"]
        print_message "District '#{district["name"]}' has (#{district["available_uids"].length}) available UIDs but (#{district["available_capacity"]}) available capacity"
      end
    end
  end

  # Populate usage hash: Only for un-ended usage records
  def populate_usage_hash(options={})
    return unless $chk_usage

    selection = {:fields => ["app_name", "created_at", "gear_id", "event", "usage_type", "cart_name", "addtl_fs_gb"],
                 :timeout => false}
    options.reverse_merge!(selection)
    OpenShift::DataStore.find(:usage_records, {}, options) do |urec|
      gear_id = urec['gear_id'].to_s
      if !UsageRecord::EVENTS.values.include?(urec['event'])
        print_message "Found record in usage_records collection with invalid event '#{urec['event']}' for gear Id '#{gear_id}'."
        next
      end

      hash = nil
      case urec['usage_type']
      when UsageRecord::USAGE_TYPES[:gear_usage]
        hash = $usage_gear_hash
      when UsageRecord::USAGE_TYPES[:addtl_fs_gb]
        hash = $usage_storage_hash
      when UsageRecord::USAGE_TYPES[:premium_cart]
        hash = $usage_cart_hash
      else
        print_message "Found invalid usage type '#{urec['usage_type']}' in usage_records collection for gear Id '#{gear_id}'."
        next
      end

      unless hash[gear_id]
        hash[gear_id] = {}
        hash[gear_id]['num_begin_recs'] = 0
        hash[gear_id]['num_end_recs'] = 0
      end
      if hash[gear_id]['created_at'].nil? or (urec['created_at'] > hash[gear_id]['created_at'])
        hash[gear_id]['app_name'] = urec['app_name']
        hash[gear_id]['created_at'] = urec['created_at']
      end
      if urec['event'] == UsageRecord::EVENTS[:end]
        hash[gear_id]['num_end_recs'] += 1
      else
        hash[gear_id]['num_begin_recs'] += 1
      end
      if urec['cart_name']
        hash[gear_id]['cart_name'] = [] unless hash[gear_id]['cart_name']
        hash[gear_id]['cart_name'] << urec['cart_name']
      end
      if urec['addtl_fs_gb']
        hash[gear_id]['addtl_fs_gb'] = urec['addtl_fs_gb']
      end
    end
    [$usage_gear_hash, $usage_storage_hash, $usage_cart_hash].each do |hash|
      hash.delete_if {|gear_id, gear_info| gear_info['num_begin_recs'] == gear_info['num_end_recs']}
    end
  end

  # Check consumed gears vs actual gears
  def find_consumed_gears_inconsistencies
    error_consumed_gears_user_ids = []
    puts "Checking for user consumed gears and actual gears" if $verbose
    $user_hash.each do |owner_id, owner_hash|
      total_gears = 0
      owner_hash["domains"].each { |dom_id, domain_gear_count| total_gears += domain_gear_count }

      if owner_hash['consumed_gears'] != total_gears
        user = CloudUser.find_by(:_id => owner_id)
        user_consumed_gears, app_actual_gears = check_consumed_gears(user)
        if user_consumed_gears != app_actual_gears
          print_message "User #{owner_hash['login']} has a mismatch in consumed gears (#{user_consumed_gears}) and actual gears (#{app_actual_gears})"
          print_message "Set the correct number of consumed gears with the oo-admin-ctl-user command:"
          print_message "oo-admin-ctl-user --login username --setconsumedgears #{app_actual_gears}"
          error_consumed_gears_user_ids << owner_id
        end
      end
    end
    error_consumed_gears_user_ids.uniq!
    error_consumed_gears_user_ids
  end

  def find_ssh_key_inconsistencies
    gear_sshkey_hash, _ = OpenShift::ApplicationContainerProxy.get_all_gears_sshkeys

    puts "Checking application gears and ssh keys on corresponding nodes" if $verbose
    current_time = Time.now.utc
    error_ssh_keys_app_ids = []
    $datastore_hash.each do |gear_uuid, gear_info|
      login = gear_info['login']
      creation_time = gear_info['creation_time'].utc
      server_identity = gear_info['server_identity']
      app_id = gear_info['app_id']
      db_sshkeys = gear_info['app_ssh_keys']

      if (current_time - creation_time) > 600
        if gear_sshkey_hash.has_key? gear_uuid
          gear_sshkeys_list = gear_sshkey_hash[gear_uuid].uniq.sort
          db_sshkeys_list = db_sshkeys.map {|arr_k| "OPENSHIFT-#{gear_uuid}-#{arr_k[0]}::#{arr_k[1]}"}.uniq.sort
          if db_sshkeys_list != gear_sshkeys_list
            puts "#{gear_uuid}...FAIL" if $verbose

            common_sshkeys = gear_sshkeys_list & db_sshkeys_list
            extra_gear_sshkeys = gear_sshkeys_list - common_sshkeys
            extra_gear_sshkeys.each do |key|
              print_message "Gear '#{gear_uuid}' has key with hash '#{key.split('::')[1]}' and comment '#{key.split('::')[0]}' on the node but not in mongo."
            end

            extra_db_sshkeys = db_sshkeys_list - common_sshkeys
            extra_db_sshkeys.each do |key|
              remove_str = "OPENSHIFT-#{gear_uuid}-"
              print_message "Gear '#{gear_uuid}' has key with hash '#{key.split('::')[1]}' and updated name '#{key.split('::')[0].sub(remove_str, '')}' in mongo but not on the node."
            end

            error_ssh_keys_app_ids << app_id
          end
        end
      end
    end
    error_ssh_keys_app_ids.uniq
  end

  def find_stale_sshkeys
    puts "Checking stale ssh keys in mongo" if $verbose
    stale_keys_domain_ids = []
    $datastore_hash.each do |gear_uuid, gear_info|
      domain_id = gear_info['domain_id']
      ref_ids = $domain_hash[domain_id]["ref_ids"]

      # check for any stale ssh keys that do not have their reference id present
      unless stale_keys_domain_ids.include? domain_id
        db_sshkeys = gear_info['app_ssh_keys']
        stale_keys = db_sshkeys.select {|k| k[2].present? and !ref_ids.include? k[2]}
        stale_keys.each do |key|
          stale_keys_domain_ids << domain_id
          print_message "Gear '#{gear_uuid}' has a stale key '#{key[0]}' in mongo with missing component/gear '#{key[2]}'."
        end
      end
    end

    # check any domains with no ref_ids - this indicates domains with no applications
    $domain_hash.each do |domain_id, domain_info|
      ref_ids = domain_info["ref_ids"]
      next if ref_ids.present?
      domain_name = domain_info["canonical_namespace"]
      unless stale_keys_domain_ids.include? domain_id
        domain_sshkeys = $domain_hash[domain_id]["ssh_keys"]
        stale_keys = domain_sshkeys.select {|k| k[2].present?}
        stale_keys.each do |key|
          stale_keys_domain_ids << domain_id
          print_message "Domain '#{domain_name}' has a stale key '#{key[0]}' in mongo with missing component/gear '#{key[2]}'."
        end
      end
    end

    stale_keys_domain_ids.uniq
  end

  def find_district_inconsistencies
    return unless $districts_enabled

    error_unreserved_district_uid_map = {}
    error_unused_district_uid_map = {}
    # check for any unreserved uid in the district
    # these are uids that gears are using but are still present in the district's available_uids
    puts "Checking for unreserved UIDs in the district" if $verbose
    $gear_uid_hash.each do |server_identity, uid_list|
      $district_hash.each do |district_uuid, district_info|
        if district_info['server_names'].include?(server_identity)
          unreserved_uids = uid_list & district_info['available_uids']
          unreserved_uids.each do |unreserved_uid|
            # skip if the UID is no longer being used by any gear or UID is no longer available in the district
            next if !datastore_has_gear_uid?(unreserved_uid, [server_identity]) or
                    !district_has_available_uid?(district_uuid, unreserved_uid)
            puts "Re-checking UID #{unreserved_uid} in district #{district_info['name']} in the database...FAIL\t" if $verbose
            print_message "UID '#{unreserved_uid}' is available in district '#{district_info['name']}' but used by a gear on node '#{server_identity}'"

            error_unreserved_district_uid_map[district_uuid] = [] unless error_unreserved_district_uid_map.has_key? district_uuid
            error_unreserved_district_uid_map[district_uuid] << unreserved_uid
          end
          break
        end
      end
    end

    # check for any unused uid in the district
    # these are uids that are reserved in the district, but no gear is using
    puts "Checking for unused UIDs in the district" if $verbose
    district_used_uids = []
    $district_hash.each do |district_uuid, district_info|
      # collect gear uids from all nodes with server identities within this district
      district_info['server_names'].each {|si| district_used_uids |= ($gear_uid_hash[si] || [])}

      first_uuid = Rails.configuration.msg_broker[:districts][:first_uid]
      district_all_uids = []
      district_all_uids.fill(0, district_info['max_capacity']) {|i| first_uuid + i}
      district_unused_uids = district_all_uids - district_info['available_uids'] - district_used_uids

      district_unused_uids.each do |unused_uid|
        # skip if found a gear that uses this UID or UID is no longer reserved in the district
        next if datastore_has_gear_uid?(unused_uid, district_info['server_names']) or
                district_has_available_uid?(district_uuid, unused_uid)
        puts "Re-checking UID #{unused_uid} in district #{district_info['name']} in the database...FAIL\t" if $verbose
        print_message "UID '#{unused_uid}' is reserved in district '#{district_info['name']}' but not used by any gear"

        error_unused_district_uid_map[district_uuid] = [] unless error_unused_district_uid_map.has_key? district_uuid
        error_unused_district_uid_map[district_uuid] << unused_uid
      end
    end

    # check to see if there are multiple gears with the same uid in the same district
    puts "Checking for gears with the same UID" if $verbose
    $district_hash.each do |district_id, district_info|
      # collect gear uids from all nodes with server identities within this district
      district_used_uids = []
      server_ids = []
      district_info['server_names'].each do |server_identity|
        server_ids << server_identity
        district_used_uids = district_used_uids.concat($gear_uid_hash[server_identity] || [])
      end
      #get all the uids that appear more than once
      reused_uids = district_used_uids.select { |e| district_used_uids.count(e) > 1 }.uniq
      if reused_uids.length > 0
        print_message "Below UIDs are used by multiple gears in district: '#{district_info['name']}'.  Please move one of them to another district."
        reused_uids.each do |uid|
          print_message "UID: #{uid} is used by gears:"
          $datastore_hash.select{|k,v| (v['gear_uid'] == uid) and server_ids.any? {|server_id| (v['server_identity'] == server_id)}}.each do |uuid, gear_info|
            print_message "\tGear:#{uuid} in #{gear_info['server_identity']}"
          end
        end
      end
    end
    [error_unreserved_district_uid_map, error_unused_district_uid_map]
  end

  # Find application gears that does not have usage records and viceversa.
  def find_app_gear_usage_record_inconsistencies
    error_usage_gear_app_gear_ids = []
    error_usage_gear_urec_gear_ids = []
    usage_gear_ids = $usage_gear_hash.keys
    app_gear_ids = $app_gear_hash.keys
    missing_gear_ids = (usage_gear_ids - app_gear_ids) + (app_gear_ids - usage_gear_ids)
    puts "Checking gears available in applications collection but not in usage_records and viceversa: " + (missing_gear_ids.empty? ? "OK" : "FAIL") if $verbose

    missing_gear_ids.each do |gear_id|
      if $app_gear_hash[gear_id]
        query = {'_id' => Moped::BSON::ObjectId($app_gear_hash[gear_id]['app_id'])}
      else
        query = {'name' => $usage_gear_hash[gear_id]['app_name']}
      end
      query['gears._id'] = Moped::BSON::ObjectId(gear_id)
      app_gear_exists = Application.where(query).exists?

      query = {'gear_id' => BSON::ObjectId(gear_id), 'usage_type' => UsageRecord::USAGE_TYPES[:gear_usage]}
      selection = {:fields => ["event"], :timeout => false}
      num_end_events = num_begin_events = 0
      OpenShift::DataStore.find(:usage_records, query, selection) do |urec|
        next if !UsageRecord::EVENTS.values.include?(urec['event'])
        if urec['event'] == UsageRecord::EVENTS[:end]
          num_end_events += 1
        else
          num_begin_events += 1
        end
      end
      usage_gear_exists = (num_begin_events > num_end_events)

      unless app_gear_exists and usage_gear_exists
        puts "Re-checking for gear '#{gear_id}'...FAIL\t" if $verbose
        if app_gear_exists
          error_usage_gear_app_gear_ids << gear_id
          print_message "Found application with gear Id '#{gear_id}' but could not find corresponding usage record."
        else
          error_usage_gear_urec_gear_ids << gear_id
          print_message "Found usage record for gear Id '#{gear_id}' but could not find corresponding gear in the application."
        end
      end
    end
    [error_usage_gear_app_gear_ids, error_usage_gear_urec_gear_ids]
  end

  # Find applications with additional storage but not in usage_records and viceversa.
  def find_app_storage_usage_record_inconsistencies
    error_usage_storage_app_gear_ids = []
    error_usage_storage_urec_gear_ids = []
    error_usage_storage_mismatch_gear_ids = []
    app_storage_hash = {}
    $app_gear_hash.each { |gear_id, gear_info| app_storage_hash[gear_id] = gear_info if gear_info['addtl_fs_gb'] != 0 }
    app_storage_gear_ids = app_storage_hash.keys
    usage_storage_gear_ids = $usage_storage_hash.keys
    missing_storage_gear_ids = (usage_storage_gear_ids - app_storage_gear_ids) + (app_storage_gear_ids - usage_storage_gear_ids)
    (app_storage_gear_ids & usage_storage_gear_ids).each do |gear_id|
      missing_storage_gear_ids << gear_id if app_storage_hash[gear_id]['addtl_fs_gb'] != $usage_storage_hash[gear_id]['addtl_fs_gb']
    end
    puts "Checking gears with additional storage in applications collection but not in usage_records and viceversa: " + (missing_storage_gear_ids.empty? ? "OK" : "FAIL") if $verbose

    missing_storage_gear_ids.each do |gear_id|
      if app_storage_hash[gear_id]
        query = {'_id' => Moped::BSON::ObjectId(app_storage_hash[gear_id]['app_id'])}
      else
        query = {'name' => $usage_storage_hash[gear_id]['app_name']}
      end
      query['gears._id'] = Moped::BSON::ObjectId(gear_id)
      app = Application.where(query).first
      app_storage = 0
      group_inst = nil
      app.gears.each do |gear|
        if gear._id.to_s == gear_id
          group_inst = gear.group_instance
          break
        end
      end if app and app.gears.present?
      app_storage = group_inst.addtl_fs_gb if group_inst and (group_inst.addtl_fs_gb != 0)

      query = {'gear_id' => BSON::ObjectId(gear_id), 'usage_type' => UsageRecord::USAGE_TYPES[:addtl_fs_gb]}
      selection = {:fields => ["event", "addtl_fs_gb"], :timeout => false}
      num_end_events = num_begin_events = addtl_fs_gb = 0
      OpenShift::DataStore.find(:usage_records, query, selection) do |urec|
        next if !UsageRecord::EVENTS.values.include?(urec['event'])
        if urec['event'] == UsageRecord::EVENTS[:end]
          num_end_events += 1
        else
          addtl_fs_gb = urec['addtl_fs_gb']
          num_begin_events += 1
        end
      end
      usage_storage = (num_begin_events > num_end_events)

      unless usage_storage and (app_storage > 0) and (app_storage == addtl_fs_gb)
        puts "Re-checking for gear '#{gear_id}'...FAIL\t" if $verbose
        if app_storage == 0
          error_usage_storage_urec_gear_ids << gear_id
          print_message "Found usage record for addtl storage with gear Id '#{gear_id}' but could not find corresponding gear with addtl storage in the application."
        elsif !usage_storage
          error_usage_storage_app_gear_ids << gear_id
          print_message "Found addtl storage for gear Id '#{gear_id}' but could not find corresponding usage record."
        else # app_storage != addtl_fs_gb
          error_usage_storage_mismatch_gear_ids << gear_id
          print_message "Found addtl storage mismatch for gear Id '#{gear_id}', #{addtl_fs_gb} in usage record vs #{app_storage} for corresponding gear in the application."
        end
      end
    end
    [error_usage_storage_app_gear_ids, error_usage_storage_urec_gear_ids, error_usage_storage_mismatch_gear_ids]
  end

  # Find applications with premium cartridges but not in usage_records and viceversa.
  def find_app_premium_cart_usage_record_inconsistencies
    error_usage_cart_app_gear_ids = []
    error_usage_cart_urec_gear_ids = []
    app_cart_hash = {}
    $app_gear_hash.each { |gear_id, gear_info| app_cart_hash[gear_id] = gear_info if gear_info['premium_carts'] and !gear_info['premium_carts'].empty? }
    app_cart_gear_ids = app_cart_hash.keys
    usage_cart_gear_ids = $usage_cart_hash.keys
    missing_cart_gear_ids = (usage_cart_gear_ids - app_cart_gear_ids) + (app_cart_gear_ids - usage_cart_gear_ids)
    (usage_cart_gear_ids & app_cart_gear_ids).each do |gear_id|
      if app_cart_hash[gear_id]['premium_carts'].sort != $usage_cart_hash[gear_id]['cart_name'].sort
        missing_cart_gear_ids << gear_id
      end
    end
    puts "Checking gears with premium cartridge in applications collection but not in usage_records and viceversa: " + (missing_cart_gear_ids.empty? ? "OK" : "FAIL") if $verbose

    premium_carts = get_premium_carts
    missing_cart_gear_ids.each do |gear_id|
      if app_cart_hash[gear_id]
        query = {'_id' => BSON::ObjectId(app_cart_hash[gear_id]['app_id'])}
      else
        query = {'name' => $usage_cart_hash[gear_id]['app_name']}
      end
      query['gears._id'] = BSON::ObjectId(gear_id)
      selection = {:fields => ["component_instances.cartridge_name"], :timeout => false}
      app_carts = []
      OpenShift::DataStore.find(:applications, query, selection) do |app|
        app['component_instances'].each do |ci|
          app_carts << ci['cartridge_name'] if premium_carts.include?(ci['cartridge_name'])
        end
      end
      app_carts.sort!

      usage_carts = []
      query = {'gear_id' => BSON::ObjectId(gear_id), 'usage_type' => UsageRecord::USAGE_TYPES[:premium_cart]}
      selection = {:fields => ["event", "cart_name"], :timeout => false}
      OpenShift::DataStore.find(:usage_records, query, selection) do |urec|
        next if !UsageRecord::EVENTS.values.include?(urec['event'])
        if urec['event'] == UsageRecord::EVENTS[:end]
          usage_carts.delete(urec['cart_name'])
        else
          usage_carts << urec['cart_name']
        end
      end
      usage_carts.sort!

      if app_carts != usage_carts
        puts "Re-checking for gear '#{gear_id}'...FAIL\t" if $verbose
        if (app_carts - usage_carts).length > 0
          error_usage_cart_app_gear_ids << gear_id
          print_message "Found premium carts #{(app_carts - usage_carts).join(',')} for gear Id '#{gear_id}' but could not find corresponding usage records."
        else
          error_usage_cart_urec_gear_ids << gear_id
          print_message "Found usage records for premium carts #{(usage_carts - app_carts).join(',')} with gear Id '#{gear_id}' but could not find corresponding gear with premium carts in the application."
        end
      end
    end
    [error_usage_cart_app_gear_ids, error_usage_cart_urec_gear_ids]
  end

  # Find records in usage_records mongo collection but not in usage and viceversa
  def find_usage_record_usage_inconsistencies
    error_usage_gear_ids = []
    error_usage_urec_gear_ids = []
    usage_records_hash = {}
    [$usage_gear_hash, $usage_storage_hash, $usage_cart_hash].each do |usage_hash|
      usage_hash.each do |gear_id, gear_info|
        usage_records_hash[gear_id] = {'num_unended_events' => 0} unless usage_records_hash[gear_id]
        if gear_info['cart_name']
          usage_records_hash[gear_id]['num_unended_events'] += gear_info['cart_name'].length
        else
          usage_records_hash[gear_id]['num_unended_events'] += 1
        end
      end
    end
    usage_hash = {}
    selection = {:fields => ["gear_id"], :timeout => false}
    OpenShift::DataStore.find(:usage, {"end_time" => nil}, selection) do |urec|
      gear_id = urec['gear_id'].to_s
      usage_hash[gear_id] = {'num_unended_events' => 0} unless usage_hash[gear_id]
      usage_hash[gear_id]['num_unended_events'] += 1
    end
    usage_record_gear_ids = usage_records_hash.keys
    usage_gear_ids = usage_hash.keys
    missing_urecs = (usage_gear_ids - usage_record_gear_ids) + (usage_record_gear_ids - usage_gear_ids)
    (usage_record_gear_ids & usage_gear_ids).each do |gear_id|
      if usage_records_hash[gear_id]['num_unended_events'] != usage_hash[gear_id]['num_unended_events']
        missing_urecs << gear_id
      end
    end
    puts "Checking un-ended records in usage_records collection but not in usage collection and viceversa: " + (missing_urecs.empty? ? "OK" : "FAIL") if $verbose

    missing_urecs.each do |gear_id|
      usage_record_begin_events = 0
      usage_record_end_events = 0
      OpenShift::DataStore.find(:usage_records, {'gear_id' => BSON::ObjectId(gear_id)}, {:fields => ["event"], :timeout => false}) do |urec|
        next if !UsageRecord::EVENTS.values.include?(urec['event'])
        if urec['event'] == UsageRecord::EVENTS[:end]
          usage_record_end_events += 1
        else
          usage_record_begin_events += 1
        end
      end
      usage_record_unended_events = usage_record_begin_events - usage_record_end_events

      usage_unended_events = Usage.where({'gear_id' => Moped::BSON::ObjectId(gear_id), 'end_time' => nil}).count

      if usage_record_unended_events != usage_unended_events
        puts "Re-checking for gear '#{gear_id}'...FAIL\t" if $verbose
        if usage_record_unended_events > usage_unended_events
          error_usage_urec_gear_ids << gear_id
          print_message "Found #{usage_record_unended_events-usage_unended_events} un-ended records in usage_records collection for gear Id '#{gear_id}' but could not find corresponding records in usage."
        else
          error_usage_gear_ids << gear_id
          print_message "Found #{usage_unended_events-usage_record_unended_events} un-ended records in usage collection for gear Id '#{gear_id}' but could not find corresponding records in usage_records."
        end
      end
    end
    [error_usage_gear_ids, error_usage_urec_gear_ids]
  end

  # Find user plan_id/plan_state inconsistencies in mongo vs billing provider
  def find_user_plan_inconsistencies
    return unless $billing_enabled

    billing_user_hash = {}
    $user_hash.each { |k,v| billing_user_hash[k] = v if v['usage_account_id'] and (v['usage_account_id'].to_i > 0) }
    unless billing_user_hash.empty?
      errors = []
      billing_api = OpenShift::BillingService.instance
      billing_api.check_inconsistencies(billing_user_hash, errors, $verbose)
      print_message errors.join("\n") if errors.present?
    end
  end

  # Find allowed gear sizes inconsistencies in domains in mongo
  # vs the valid gear sizes defined in the broker configuration
  def find_domain_gear_sizes_inconsistencies
    invalid_gear_sizes = $domain_gear_sizes - Rails.configuration.openshift[:gear_sizes]
    if invalid_gear_sizes.present?
      print_message "Some domains have invalid gear sizes allowed: #{invalid_gear_sizes.join(',')}"
    end
    invalid_gear_sizes
  end

  # Find gear sizes inconsistencies for user capabilities in mongo
  # vs the valid gear sizes defined in the broker configuration
  def find_user_gear_sizes_inconsistencies
    invalid_gear_sizes = $user_gear_sizes - Rails.configuration.openshift[:gear_sizes]
    if invalid_gear_sizes.present?
      print_message "Some users have invalid gear sizes in their capabilities: #{invalid_gear_sizes.join(',')}"
    end
    invalid_gear_sizes
  end
end
