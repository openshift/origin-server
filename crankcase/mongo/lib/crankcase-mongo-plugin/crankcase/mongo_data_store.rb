require 'rubygems'
require 'mongo'
require 'pp'

module Crankcase
  class MongoDataStore < StickShift::DataStore
    MAX_CON_RETRIES   = 60
    CON_RETRY_WAIT_TM = 0.5 # in secs

    attr_reader :replica_set, :host_port, :user, :password, :db, :collections
 
    def initialize(access_info = nil)
      if access_info != nil
        # no-op
      elsif defined? Rails
        access_info = Rails.application.config.datastore
      else
        raise Exception.new("Mongo DataStore service is not inilialized")
      end
      @replica_set = access_info[:replica_set]
      @host_port = access_info[:host_port]
      @user = access_info[:user]
      @password = access_info[:password]
      @db = access_info[:db]
      @collections = access_info[:collections]
    end
     
    def self.instance
      Crankcase::MongoDataStore.new
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
    
    def find_all(obj_type, user_id=nil, f=nil)
      Rails.logger.debug "MongoDataStore.find_all(#{obj_type}, #{user_id}, #{f})\n\n"
      case obj_type
      when "CloudUser"
        get_users
      when "Application"
        get_apps(user_id)
      when "Domain"
        get_domains(user_id)
      when "ApplicationTemplate"
        if f.nil? || f.empty?
          find_all_application_templates()
        else
          find_application_template_by_tag(f[:tag])
        end
      end
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
    
    def save(obj_type, user_id, id, obj_attrs)
      Rails.logger.debug "MongoDataStore.save(#{obj_type}, #{user_id}, #{id}, #hidden)\n\n"
      case obj_type
      when "CloudUser"
        put_user(user_id, obj_attrs)
      when "Application"
        put_app(user_id, id, obj_attrs)
      when "Domain"
        put_domain(user_id, id, obj_attrs)
      end
    end
    
    def create(obj_type, user_id, id, obj_attrs)
      Rails.logger.debug "MongoDataStore.create(#{obj_type}, #{user_id}, #{id}, #{obj_attrs.pretty_inspect})\n\n"
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
      end
    end

    def db
      if @replica_set
        con = Mongo::ReplSetConnection.new(*@host_port << {:read => :secondary})
      else
        con = Mongo::Connection.new(@host_port[0], @host_port[1])
      end
      user_db = con.db(@db)
      user_db.authenticate(@user, @password)
      user_db
    end

    def collection
      db.collection(@collections[:user])
    end

    def find_one(*args)
      MongoDataStore.rescue_con_failure do
        collection.find_one(*args)
      end
    end

    def find_and_modify(*args)
      MongoDataStore.rescue_con_failure do
        collection.find_and_modify(*args)
      end
    end

    def insert(*args)
      MongoDataStore.rescue_con_failure do
        collection.insert(*args)
      end
    end

    def update(*args)
      MongoDataStore.rescue_con_failure do
        collection.update(*args)
      end
    end

    def remove(*args)
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
      hash = find_one( "_id" => user_id )
      return nil unless hash && !hash.empty?

      user_hash_to_ret(hash)
    end
    
    def get_user_by_uuid(uuid)
      hash = find_one( "uuid" => uuid )
      return nil unless hash && !hash.empty?
      
      user_hash_to_ret(hash)
    end
    
    def get_user_by_app_uuid(uuid)
      hash = find_one( "apps.uuid" => uuid )
      return nil unless hash && !hash.empty?
      
      user_hash_to_ret(hash)
    end
    
    def get_user_by_domain_uuid(uuid)
      hash = find_one( "domains.uuid" => uuid )
      return nil unless hash && !hash.empty?
      
      user_hash_to_ret(hash)
    end
    
    def get_users
      MongoDataStore.rescue_con_failure do
        mcursor = collection.find()
        ret = []
        mcursor.each do |hash|
          ret.push(user_hash_to_ret(hash))
        end
        ret
      end
    end
    
    def user_hash_to_ret(hash)
      hash.delete("_id")
      if hash["apps"] 
        hash["apps"] = apps_hash_to_apps_ret(hash["apps"])
      end
      if hash["domains"] 
        hash["domains"] = domains_hash_to_domains_ret(hash["domains"])
      end
      hash
    end

    def get_app(user_id, id)
      hash = find_one({ "_id" => user_id, "apps.name" => id }, :fields => ["apps"])
      return nil unless hash && !hash.empty?

      app_hash = nil
      hash["apps"].each do |app|
        if app["name"] == id
          app_hash = app
          break
        end
      end if hash["apps"]
      app_hash_to_ret(app_hash)
    end
  
    def get_apps(user_id)
      hash = find_one({ "_id" => user_id }, :fields => ["apps"] )
      return [] unless hash && !hash.empty?
      return [] unless hash["apps"] && !hash["apps"].empty?
      apps_hash_to_apps_ret(hash["apps"])
    end
    
    def get_domain(user_id, id)
      hash = find_one({ "_id" => user_id, "domains.uuid" => id }, :fields => ["domains"])
      return nil unless hash && !hash.empty?

      domain_hash = nil
      hash["domains"].each do |domain|
        if domain["uuid"] == id
          domain_hash = domain
          break
        end
      end if hash["domains"]
      domain_hash_to_ret(domain_hash)
    end
  
    def get_domains(user_id)
      hash = find_one({ "_id" => user_id }, :fields => ["domains"] )
      return [] unless hash && !hash.empty?
      return [] unless hash["domains"] && !hash["domains"].empty?
      domains_hash_to_domains_ret(hash["domains"])
    end


    def put_user(user_id, changed_user_attrs)
      changed_user_attrs.delete("apps")
      changed_user_attrs.delete("domains")
      changed_user_attrs.delete("consumed_gears")

      update({ "_id" => user_id }, { "$set" => changed_user_attrs })
    end
    
    def add_user(user_id, user_attrs)
      user_attrs["_id"] = user_id
      user_attrs.delete("apps")
      user_attrs.delete("domains")
      insert(user_attrs)
      user_attrs.delete("_id")
    end

    def put_app(user_id, id, app_attrs)
      app_attrs_to_internal(app_attrs)
      ngears = app_attrs["ngears"]
      ngears = ngears.to_i
      app_attrs.delete("ngears")

      if ngears > 0
        hash = find_and_modify({ :query => { "_id" => user_id, "apps.name" => id,
               "$where" => "(this.consumed_gears + #{ngears}) <= this.max_gears"},
               :update => { "$set" => { "apps.$" => app_attrs }, "$inc" => { "consumed_gears" => ngears}}})
        raise StickShift::UserException.new("Application limit has reached for '#{user_id}'", 104) if hash == nil
      elsif ngears < 0
        hash = find_and_modify({ :query => { "_id" => user_id, "apps.name" => id,
               "$where" => "this.consumed_gears + #{ngears} >= 0"},
               :update => { "$set" => { "apps.$" => app_attrs }, "$inc" => { "consumed_gears" => ngears}}})
        raise StickShift::UserException.new("Application gears already at zero for '#{user_id}'", 135) if hash == nil
      else
        update({ "_id" => user_id, "apps.name" => id}, { "$set" => { "apps.$" => app_attrs }} )
      end
    end

    def add_app(user_id, id, app_attrs)
      app_attrs_to_internal(app_attrs)
      ngears = app_attrs["ngears"]
      ngears = ngears.to_i
      app_attrs.delete("ngears")

      hash = find_and_modify({ :query => { "_id" => user_id, "apps.name" => { "$ne" => id }, "domains" => {"$exists" => true}, 
             "$where" => "((this.consumed_gears + #{ngears}) <= this.max_gears) && (this.domains.length > 0)"},
             :update => { "$push" => { "apps" => app_attrs }, "$inc" => { "consumed_gears" => ngears }} })
      raise StickShift::UserException.new("Failed: Either application limit has already reached or " +
                                          "domain doesn't exist for '#{user_id}'", 104) if hash == nil
    end
    
    def put_domain(user_id, id, domain_attrs)
      domain_attrs_to_internal(domain_attrs)
      update({ "_id" => user_id, "domains.uuid" => id}, { "$set" => { "domains.$" => domain_attrs }} )
    end

    def add_domain(user_id, id, domain_attrs)
      domain_attrs_to_internal(domain_attrs)
      hash = find_and_modify({ :query => { "_id" => user_id, "domains.uuid" => { "$ne" => id }},
             :update => { "$push" => { "domains" => domain_attrs } } })
      #raise StickShift::UserException.new("#{user_id} has already reached the domain limit", 104) if hash == nil
    end

    def delete_user(user_id)
      remove({ "_id" => user_id, "$or" => [{"domains" => {"$exists" => true, "$size" => 0}}, 
             {"domains" => {"$exists" => false}}], "$where" => "this.consumed_gears == 0"})
    end

    def delete_app(user_id, id)
      update({ "_id" => user_id, "apps.name" => id},
             { "$pull" => { "apps" => {"name" => id }}})
    end

    def app_attrs_to_internal(app_attrs)
      app_attrs
    end
    
    def app_hash_to_ret(app_hash)
      app_hash
    end
    
    def apps_hash_to_apps_ret(apps_hash)
      ret = []
      ret = apps_hash.map { |app_hash| app_hash_to_ret(app_hash) } if apps_hash
      ret
    end
    
    def delete_domain(user_id, id)
      hash = find_and_modify({ :query => { "_id" => user_id, "domains.uuid" => id,
                               "$or" => [{"apps" => {"$exists" => true, "$size" => 0}}, 
                                         {"apps" => {"$exists" => false}}] },
                               :update => { "$pull" => { "domains" => {"uuid" => id } } }})
      raise StickShift::UserException.new("Could not delete domain." +
                                          "Domain has valid applications.", 136) if hash == nil
    end

    def domain_attrs_to_internal(domain_attrs)
      domain_attrs
    end
    
    def domain_hash_to_ret(domain_hash)
      domain_hash
    end
    
    def domains_hash_to_domains_ret(domains_hash)
      ret = []
      ret = domains_hash.map { |domain_hash| domain_hash_to_ret(domain_hash) } if domains_hash
      ret
    end
  end
end
