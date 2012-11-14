require 'rubygems'
require 'mongo'
require 'pp'

module OpenShift
  class MongoDataStore < OpenShift::DataStore
    MAX_CON_RETRIES   = 60
    CON_RETRY_WAIT_TM = 0.5 # in secs

    attr_reader :replica_set, :host_port, :user, :password, :db, :collections
 
    def initialize(access_info = nil)
      if access_info != nil
        # no-op
      elsif defined? Rails
        access_info = Rails.application.config.datastore
      else
        raise Exception.new("Mongo DataStore service is not initialized")
      end
      @replica_set = access_info[:replica_set]
      @host_port = access_info[:host_port]
      @user = access_info[:user]
      @password = access_info[:password]
      @db = access_info[:db]
      @collections = access_info[:collections]
    end
     
    def self.instance
      OpenShift::MongoDataStore.new
    end

    def find(obj_type, user_id, id)
      Rails.logger.debug "MongoDataStore.find(#{obj_type}, #{user_id}, #{id})\n\n"
      case obj_type
      when "CloudUser"
        get_user(user_id)
      when "Application"
        get_app(user_id, id)
      when "Domain"
        get_domain(user_id, id)
      when "ApplicationTemplate"
        find_application_template(id)
      end
    end
    
    def find_all(obj_type, user_id=nil, opts=nil, &block)
      Rails.logger.debug "MongoDataStore.find_all(#{obj_type}, #{user_id}, #{opts})\n\n"
      case obj_type
      when "CloudUser"
        get_users(opts, &block)
      when "Application"
        get_apps(user_id, &block)
      when "Domain"
        get_domains(user_id, &block)
      when "ApplicationTemplate"
        if opts.nil? || opts.empty?
          find_all_application_templates(&block)
        else
          find_application_template_by_tag(opts[:tag], &block)
        end
      end
    end

    def find_all_logins(opts)
      Rails.logger.debug "MongoDataStore.find_all_logins()\n\n"
      query = {}
      if opts
        if opts[:with_gears]
          query["apps.group_instances.gears.0"] = {"$exists" => true}
        end
        if opts[:with_usage]
          query["usage_records.0"] = {"$exists" => true}
        end
        if opts[:with_plan]
          query["$or"] = [{"pending_plan_id" => {"$ne" => nil}}, {"plan_id" => {"$ne" => nil}}]
        end
      end
      mcursor = user_collection.find(query, {:fields => []})
      ret = []
      mcursor.each do |hash|
        ret.push(hash['_id'])
      end
      ret
    end

    def find_by_gear_uuid(gear_uuid)
      Rails.logger.debug "MongoDataStore.find_by_gear_uuid(#{gear_uuid})\n\n"
      hash = find_one( user_collection, { "apps.group_instances.gears.uuid" => gear_uuid } )
      return nil unless hash
      user_hash_to_ret(hash)
    end
    
    def find_by_uuid(obj_type_of_uuid, uuid)
      Rails.logger.debug "MongoDataStore.find_by_uuid(#{obj_type_of_uuid}, #{uuid})\n\n"
      case obj_type_of_uuid
      when "CloudUser"
        get_user_by_uuid(uuid)
      when "Application"
        get_user_by_app_uuid(uuid)
      when "Domain"
        get_user_by_domain_uuid(uuid)
      when "ApplicationTemplate"
        find_application_template(uuid)
      end
    end
    
    def find_subaccounts_by_parent_login(parent_id)
      Rails.logger.debug "MongoDataStore.find_subaccounts_by_parent_login(#{parent_id})\n\n"
      cur = MongoDataStore.rescue_con_failure { user_collection.find({ "parent_user_login" => parent_id }) }
      return [] unless cur
      hash_list = []
      cur.each do |hash|
        hash.delete("_id")
        hash_list << hash
      end

      hash_list
    end

    def save(obj_type, user_id, id, obj_attrs)
      Rails.logger.debug "MongoDataStore.save(#{obj_type}, #{user_id}, #{id}, #hidden)\n\n"
      case obj_type
      when "CloudUser"
        put_user(user_id, obj_attrs)
      when "Application"
        put_app(user_id, id, obj_attrs)
      when "Domain"
        put_domain(user_id, id, obj_attrs)
      when "UsageRecord"
        put_usage_record(user_id, id, obj_attrs)
      end
    end
    
    def create(obj_type, user_id, id, obj_attrs)
      Rails.logger.debug "MongoDataStore.create(#{obj_type}, #{user_id}, #{id}, #hidden)\n\n"      
      case obj_type
      when "CloudUser"
        add_user(user_id, obj_attrs)
      when "Application"
        add_app(user_id, id, obj_attrs)
      when "Domain"
        add_domain(user_id, id, obj_attrs)
      when "ApplicationTemplate"
        save_application_template(id, obj_attrs)
      end
    end
    
    def delete(obj_type, user_id, id=nil)
      Rails.logger.debug "MongoDataStore.delete(#{obj_type}, #{user_id}, #{id})\n\n"
      case obj_type
      when "CloudUser"
        delete_user(user_id)
      when "Application"
        delete_app(user_id, id)
      when "Domain"
        delete_domain(user_id, id)
      when "ApplicationTemplate"
        delete_application_template(id)
      when "UsageRecord"
        delete_usage_record(user_id, id)
      end
    end

    def delete_usage_record_by_gear_uuid(user_id, gear_uuid, usage_type)
      Rails.logger.debug "MongoDataStore.delete_usage_record_by_gear_uuid(#{user_id}, #{gear_uuid}, #{usage_type})\n\n"
      update( user_collection, { "_id" => user_id },
                               { "$pull" => { "usage_records" => {"gear_uuid" => gear_uuid, "usage_type" => usage_type}}} )
    end
    
    def delete_usage_records_by_uuids(user_id, uuids)
      Rails.logger.debug "MongoDataStore.delete_usage_record_by_gear_uuid(#{user_id}, #{uuids})\n\n"
      update( user_collection, { "_id" => user_id },
                               { "$pull" => { "usage_records" => {"uuid" => {"$in" => uuids}} }} )
    end

    def db
      if @replica_set
        con = Mongo::ReplSetConnection.new(*@host_port << {:read => :secondary, :connect_timeout => 60})
      else
        con = Mongo::Connection.new(@host_port[0], @host_port[1])
      end
      user_db = con.db(@db)
      user_db.authenticate(@user, @password)
      user_db
    end

    def user_collection
      db.collection(@collections[:user])
    end

    def find_one(collection, *args)
      MongoDataStore.rescue_con_failure do
        collection.find_one(*args)
      end
    end

    def find_and_modify(collection, *args)
      MongoDataStore.rescue_con_failure do
        collection.find_and_modify(*args)
      end
    end

    def insert(collection, *args)
      MongoDataStore.rescue_con_failure do
        collection.insert(*args)
      end
    end

    def update(collection, *args)
      MongoDataStore.rescue_con_failure do
        collection.update(*args)
      end
    end

    def remove(collection, *args)
      MongoDataStore.rescue_con_failure do
        collection.remove(*args)
      end
    end

    # Ensure retry upon connection failure
    def self.rescue_con_failure(max_retries=MAX_CON_RETRIES, retry_wait_tm=CON_RETRY_WAIT_TM)
      retries = 0
      begin
        yield
      rescue Mongo::ConnectionFailure => ex
        retries += 1
        raise ex if retries > max_retries
        sleep(retry_wait_tm)
        retry
      end
    end

    def find_district(uuid)
      Rails.logger.debug "MongoDataStore.find_district(#{uuid})\n\n"
      hash = find_one( district_collection, "_id" => uuid )
      hash_to_district_ret(hash)
    end
    
    def find_district_by_name(name)
      Rails.logger.debug "MongoDataStore.find_district_by_name(#{name})\n\n"
      hash = find_one( district_collection, "name" => name )
      hash_to_district_ret(hash)
    end
    
    def find_all_districts()
      Rails.logger.debug "find_all_districts()\n\n"
      MongoDataStore.rescue_con_failure do
        mcursor = district_collection.find()
        cursor_to_district_hash(mcursor)
      end
    end
    
    def find_district_with_node(server_identity)
      Rails.logger.debug "find_district_with_node(#{server_identity})\n\n"
      hash = find_one( district_collection, {"server_identities.name" => server_identity } )
      hash_to_district_ret(hash)
    end
    
    def save_district(uuid, district_attrs)
      Rails.logger.debug "save_district(#{uuid}, #{district_attrs.pretty_inspect})\n\n"
      district_attrs["_id"] = uuid
      orig_server_identities = district_attrs["server_identities"] 
      district_attrs_to_internal(district_attrs)
      update( district_collection, { "_id" => uuid }, district_attrs, { :upsert => true } )
      district_attrs.delete("_id")
      district_attrs["server_identities"] = orig_server_identities
    end
    
    def delete_district(uuid)
      Rails.logger.debug "delete_district(#{uuid})\n\n"
      remove( district_collection, { "_id" => uuid, "active_server_identities_size" => 0 } )
    end

    def reserve_district_uid(uuid)
      Rails.logger.debug "reserve_district_uid(#{uuid})\n\n"
      hash = find_and_modify( district_collection, {
        :query => {"_id" => uuid, "available_capacity" => {"$gt" => 0}},
        :update => {"$pop" => { "available_uids" => -1}, "$inc" => { "available_capacity" => -1 }},
        :new => false })
      return hash ? hash["available_uids"][0] : nil
    end

    def unreserve_district_uid(uuid, uid)
      Rails.logger.debug "unreserve_district_uid(#{uuid})\n\n"
      update( district_collection, {"_id" => uuid, "available_uids" => {"$ne" => uid}}, {"$push" => { "available_uids" => uid}, "$inc" => { "available_capacity" => 1 }} )
    end
    
    def add_district_node(uuid, server_identity)
      Rails.logger.debug "add_district_node(#{uuid},#{server_identity})\n\n"
      update( district_collection, {"_id" => uuid, "server_identities.name" => { "$ne" => server_identity }}, {"$push" => { "server_identities" => {"name" => server_identity, "active" => true}}, "$inc" => { "active_server_identities_size" => 1 }} )
    end

    def remove_district_node(uuid, server_identity)
      Rails.logger.debug "remove_district_node(#{uuid},#{server_identity})\n\n"
      hash = find_and_modify( district_collection, {
        :query => { "_id" => uuid, "server_identities" => {"$elemMatch" => {"name" => server_identity, "active" => false}}}, 
        :update => { "$pull" => { "server_identities" => {"name" => server_identity }}} })
      return hash != nil
    end
    
    def deactivate_district_node(uuid, server_identity)
      Rails.logger.debug "deactivate_district_node(#{uuid},#{server_identity})\n\n"
      update( district_collection, {"_id" => uuid, "server_identities" => {"$elemMatch" => {"name" => server_identity, "active" => true}}}, {"$set" => { "server_identities.$.active" => false}, "$inc" => { "active_server_identities_size" => -1 }} )
    end

    def activate_district_node(uuid, server_identity)
      Rails.logger.debug "activate_district_node(#{uuid},#{server_identity})\n\n"
      update( district_collection, {"_id" => uuid, "server_identities" => {"$elemMatch" => {"name" => server_identity, "active" => false}}}, {"$set" => { "server_identities.$.active" => true}, "$inc" => { "active_server_identities_size" => 1 }} )
    end

    def add_district_uids(uuid, uids)
      Rails.logger.debug "add_district_capacity(#{uuid},#{uids})\n\n"
      update( district_collection, {"_id" => uuid}, {"$pushAll" => { "available_uids" => uids }, "$inc" => { "available_capacity" => uids.length, "max_uid" => uids.length, "max_capacity" => uids.length }} )
    end

    def remove_district_uids(uuid, uids)
      Rails.logger.debug "remove_district_capacity(#{uuid},#{uids})\n\n"
      update( district_collection, {"_id" => uuid, "available_uids" => uids[0]}, {"$pullAll" => { "available_uids" => uids }, "$inc" => { "available_capacity" => -uids.length, "max_uid" => -uids.length, "max_capacity" => -uids.length }} )
    end

    def inc_district_externally_reserved_uids_size(uuid)
      Rails.logger.debug "inc_district_externally_reserved_uids_size(#{uuid})\n\n"
      update( district_collection, {"_id" => uuid}, {"$inc" => { "externally_reserved_uids_size" => 1 }} )
    end

    def find_available_district(node_profile=nil)
      node_profile = node_profile ? node_profile : "small"
      MongoDataStore.rescue_con_failure do
        hash = district_collection.find(
          { "available_capacity" => { "$gt" => 0 }, 
            "active_server_identities_size" => { "$gt" => 0 },
            "node_profile" => node_profile}).sort(["available_capacity", "descending"]).limit(1).next
        hash_to_district_ret(hash)
      end
    end

    private
    
    def find_application_template_by_tag(tag)
      arr = application_template_collection.find( {"tags" => tag} )
      return nil if arr.nil?
      templates = []
      arr.each do |hash|
        hash.delete("_id")
        templates.push(hash)
      end
      templates
    end
    
    def find_application_template(id)
      hash = application_template_collection.find_one( {"_id" => id} )        
      return nil if hash.nil?
      hash.delete("_id")
      hash
    end
    
    def find_all_application_templates()
      arr = application_template_collection.find()
      return nil if arr.nil?
      templates = []
      arr.each do |hash|
        hash.delete("_id")
        templates.push(hash)
      end
      templates
    end
    
    def save_application_template(uuid, attrs)
      Rails.logger.debug "MongoDataStore.save_application_template(#{uuid}, #{attrs.pretty_inspect})\n\n"
      attrs["_id"] = uuid
      application_template_collection.update({ "_id" => uuid }, attrs, { :upsert => true })
      attrs.delete("_id")
    end
    
    def delete_application_template(uuid)
      Rails.logger.debug "MongoDataStore.delete_application_template(#{uuid})\n\n"
      application_template_collection.remove({ "_id" => uuid })
    end
    
    def application_template_collection
      db.collection(@collections[:application_template])
    end

    def get_user(user_id)
      hash = find_one( user_collection, "_id" => user_id )
      return nil unless hash && !hash.empty?

      user_hash_to_ret(hash)
    end
    
    def get_user_by_uuid(uuid)
      hash = find_one( user_collection, "uuid" => uuid )
      return nil unless hash && !hash.empty?
      
      user_hash_to_ret(hash)
    end
    
    def get_user_by_app_uuid(uuid)
      hash = find_one( user_collection, "apps.uuid" => uuid )
      return nil unless hash && !hash.empty?
      
      user_hash_to_ret(hash)
    end
    
    def get_user_by_domain_uuid(uuid)
      hash = find_one( user_collection, "domains.uuid" => uuid )
      return nil unless hash && !hash.empty?
      
      user_hash_to_ret(hash)
    end
    
    def get_users(opts=nil)
      MongoDataStore.rescue_con_failure do
        query = {}
        if opts
          if opts[:with_gears]
            query["apps.group_instances.gears.0"] = {"$exists" => true}
          end
          if opts[:with_usage]
            query["usage_records.0"] = {"$exists" => true}
          end
          if opts[:with_plan]
            query["$or"] = [{"pending_plan_id" => {"$ne" => nil}}, {"plan_id" => {"$ne" => nil}}]
          end
        end
        mcursor = user_collection.find(query)
        ret = []
        mcursor.each do |hash|
          if block_given?
            yield user_hash_to_ret(hash)
          else
            ret.push(user_hash_to_ret(hash))
          end
        end
        ret
      end
    end

    def user_hash_to_ret(hash)
      hash.delete("_id")
      hash
    end

    def get_app(user_id, id)
      hash = find_one( user_collection, { "_id" => user_id, "apps.name" => /^#{id}$/i }, :fields => ["apps"])
      return nil unless hash && !hash.empty?

      app_hash = nil
      hash["apps"].each do |app|
        if app["name"].downcase == id.downcase
          app_hash = app
          break
        end
      end if hash["apps"]
      app_hash
    end
  
    def get_apps(user_id)
      hash = find_one( user_collection, { "_id" => user_id }, :fields => ["apps"] )
      return [] unless hash && !hash.empty?
      return [] unless hash["apps"] && !hash["apps"].empty?
      hash["apps"]
    end
    
    def get_domain(user_id, id)
      hash = find_one( user_collection, { "_id" => user_id, "domains.uuid" => id }, :fields => ["domains"] )
      return nil unless hash && !hash.empty?

      domain_hash = nil
      hash["domains"].each do |domain|
        if domain["uuid"] == id
          domain_hash = domain
          break
        end
      end if hash["domains"]
      domain_hash
    end
  
    def get_domains(user_id)
      hash = find_one( user_collection, { "_id" => user_id }, :fields => ["domains"] )
      return [] unless hash && !hash.empty?
      return [] unless hash["domains"] && !hash["domains"].empty?
      hash["domains"]
    end


    def put_user(user_id, changed_user_attrs)
      changed_user_attrs.delete("apps")
      changed_user_attrs.delete("domains")
      changed_user_attrs.delete("consumed_gears")
      changed_user_attrs.delete("usage_records")

      update( user_collection, { "_id" => user_id }, { "$set" => changed_user_attrs } )
    end

    def add_user(user_id, user_attrs)
      user_attrs["_id"] = user_id
      user_attrs.delete("apps")
      user_attrs.delete("domains")
      insert(user_collection, user_attrs)
      user_attrs.delete("_id")
    end

    def put_app(user_id, id, app_attrs)
      app_attrs_to_internal(app_attrs)
      ngears = app_attrs["ngears"]
      ngears = ngears.to_i
      app_attrs.delete("ngears")
      usage_records = app_attrs["usage_records"]
      app_attrs.delete("usage_records")
      destroyed_gears = app_attrs["destroyed_gears"]
      app_attrs.delete("destroyed_gears")

      updates = { "$set" => { "apps.$" => app_attrs } }
      if usage_records && !usage_records.empty?
        updates["$pushAll"] = { "usage_records" => usage_records }
      end
      if ngears != 0
        updates["$inc"] = { "consumed_gears" => ngears }
        query = { "_id" => user_id, "apps.name" => id }
        if ngears > 0
          condition = "(this.consumed_gears + #{ngears}) <= this.max_gears"
          query["$where"] = condition
        end
        
        if destroyed_gears && !destroyed_gears.empty?
          query["apps.group_instances.gears.uuid"] = { "$all" => destroyed_gears }
        end

        hash = find_and_modify( user_collection, { :query => query,
               :update => updates })
        raise OpenShift::UserException.new("Consistency check failed.  Could not update application '#{id}' for '#{user_id}'", 1) if hash == nil
      else
        update( user_collection, { "_id" => user_id, "apps.name" => id}, updates )
      end
    end

    def add_app(user_id, id, app_attrs)
      app_attrs_to_internal(app_attrs)
      ngears = app_attrs["ngears"]
      ngears = ngears.to_i
      app_attrs.delete("ngears")
      usage_records = app_attrs["usage_records"]
      app_attrs.delete("usage_records")
      app_attrs.delete("destroyed_gears")
      
      updates = { "$push" => { "apps" => app_attrs }, "$inc" => { "consumed_gears" => ngears }}
      if usage_records && !usage_records.empty?
        updates["$pushAll"] = { "usage_records" => usage_records }
      end

      hash = find_and_modify( user_collection, { :query => { "_id" => user_id, "apps.name" => { "$ne" => id }, "domains" => {"$exists" => true}, 
             "$where" => "((this.consumed_gears + #{ngears}) <= this.max_gears) && (this.domains.length > 0)"},
             :update => updates })
      raise OpenShift::UserException.new("Failed: Either application limit has already reached or " +
                                          "domain doesn't exist for '#{user_id}'", 104) if hash == nil
    end
    
    def put_domain(user_id, id, domain_attrs)
#TODO: FIXME
#      domain_updates = {}
#      domain_attrs.each do |k, v|
#        domain_updates["domains.$.#{k}"] = v
#        domain_updates["apps.$.domain.#{k}"] = v
#      end
#      update( user_collection, { "_id" => user_id, "domains.uuid" => id}, { "$set" => domain_updates } )
      update( user_collection, { "_id" => user_id, "domains.uuid" => id}, { "$set" => { "domains.$" => domain_attrs }} )
    end

#TODO: Revisit the query once we support multiple domains per user
    def add_domain(user_id, id, domain_attrs)
      hash = find_and_modify( user_collection, { :query => { "_id" => user_id, "domains.uuid" => { "$ne" => id },
             "$or" => [{"domains" => {"$exists" => true, "$size" => 0}}, {"domains" => {"$exists" => false}}]},
             :update => { "$push" => { "domains" => domain_attrs } } })
      raise OpenShift::UserException.new("Domain already exists for #{user_id}", 158) if hash == nil
    end

    def delete_user(user_id)
      remove( user_collection, { "_id" => user_id, "$or" => [{"domains" => {"$exists" => true, "$size" => 0}}, 
             {"domains" => {"$exists" => false}}], "$where" => "this.consumed_gears == 0"} )
    end

    def delete_app(user_id, id)
      update( user_collection, { "_id" => user_id, "apps.name" => id},
             { "$pull" => { "apps" => {"name" => id }}})
    end

    def put_usage_record(user_id, id, usage_attrs)
      update( user_collection, { "_id" => user_id, "usage_records.uuid" => id}, { "$set" => { "usage_records.$" => usage_attrs }} )
    end
    
    def delete_usage_record(user_id, id)
      update( user_collection, { "_id" => user_id,  },
             { "$pull" => { "usage_records" => {"uuid" => id }}} )
    end

    def app_attrs_to_internal(app_attrs)
      app_attrs
    end
    
    def delete_domain(user_id, id)
      hash = find_and_modify( user_collection, { :query => { "_id" => user_id, "domains.uuid" => id,
                               "$or" => [{"apps" => {"$exists" => true, "$size" => 0}}, 
                                         {"apps" => {"$exists" => false}}] },
                               :update => { "$pull" => { "domains" => {"uuid" => id } } }})
      raise OpenShift::UserException.new("Could not delete domain." +
                                          "Domain has valid applications.", 128) if hash == nil
    end

    #district
          
    def district_collection
      db.collection(@collections[:district])
    end

    def cursor_to_district_hash(cursor)
      return [] unless cursor
  
      districts = []
      cursor.each do |hash|
        districts.push(hash_to_district_ret(hash))
      end
      districts
    end

    def hash_to_district_ret(hash)
      return nil unless hash
      hash.delete("_id")
      if hash["server_identities"]
        server_identities = {}
        hash["server_identities"].each do |server_identity|
          name = server_identity["name"]
          server_identity.delete("name")
          server_identities[name] = server_identity
        end
        hash["server_identities"] = server_identities
      else
        hash["server_identities"] = {}
      end
      hash
    end
    
    def district_attrs_to_internal(district_attrs)
      if district_attrs
        if district_attrs["server_identities"]
          server_identities = []
          district_attrs["server_identities"].each do |name, server_identity|
            server_identity["name"] = name
            server_identities.push(server_identity)
          end
          district_attrs["server_identities"] = server_identities
        else
          district_attrs["server_identities"] = []
        end
      end
      district_attrs
    end
  end
end
