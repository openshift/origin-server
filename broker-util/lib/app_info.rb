#!/usr/bin/env oo-ruby

#   Copyright 2012 Red Hat Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require "#{ENV['OPENSHIFT_BROKER_DIR'] || '/var/www/openshift/broker'}/config/environment"

Rails.configuration.analytics[:enabled] = false
Mongoid.raise_not_found_error = false

class AppInfo
  attr_accessor :user, :domain, :app, :domain_suffix

  def initialize(user, domain, app)
    @user = user
    @domain = domain
    @app = app
    @domain_suffix = Rails.configuration.openshift[:domain_suffix]
  end

  def to_h()
    retval = { 'domain_suffix' => @domain_suffix }
    retval['user'] = JSON.parse(@user.to_json) if @user
    retval['domain'] = JSON.parse(@domain.to_json) if @domain
    retval['app'] = JSON.parse(@app.to_json) if @app

    # don't show cart passwords.
    def redact(obj)
      if obj.is_a? Hash
        obj.each { |k,v|
          obj[k] = '!REDACTED!' if k =~ /password/i
          obj['value'] = '!REDACTED!' if k == 'key' and v =~ /password/i
          redact(v) if [Hash, Array].include?(v.class)
        }
      elsif obj.is_a? Array
        obj.each { |v| redact(v) }
      end
    end

    return redact(retval)
  end

  def to_s()
    url = "#{@app.name}-#{@domain.namespace}.#{@domain_suffix}"
    cur_dns = `/usr/bin/host #{url}`
    begin
      template = <<-EOS
      Login:         <%= @user.login %>
      Plan:          <%= @user.plan_id %> (<%= @user.plan_state %>)

      App Name:      <%= @app.name %>
      App UUID:      <%= @app.uuid %>
      Creation Time: <%= @app.created_at.strftime("%Y-%m-%d %I:%M:%S %p") %>
      URL:           http://<%= url %>
    <% @app.group_instances.each_with_index do |gi,i| %>
      Group Instance[<%= i %>]:
          Components: <% gi.component_instances.each do |gear| %>
              Cartridge Name: <%= gear.cartridge_name %>
              Component Name: <%= gear.component_name %> <% end %>
          <% gi.gears.each_with_index do |gear,j| %> Gear[<%= j %>]
              Server Identity: <%= gear.server_identity %>
              Gear UUID:       <%= gear.uuid %>
              Gear UID:        <%= gear["uid"] %>
          <% end %><% end %>
      Current DNS
      -----------
    <% cur_dns.split("\n").each do |line| %> <%= line %>
    <% end %>
      EOS

        return ERB.new(template, 0, '<>').result(binding)
      rescue NoMethodError => e
        return "#{RED}Error:#{NORM} Problem compiling output for #{url}. Please validate the application's entries in Mongo."
    end
  end
end

class AppQuery
  FQDN_REGEX = /(http:\/\/)?(\w+)-(\w+)(\.\w+)?\.#{Regexp.escape(Rails.application.config.openshift[:domain_suffix])}\Z/

  #
  # Entrypoint for openshift application query methods
  #
  # Parameters:
  #   query - app query string or regex
  #   qtype - query type (app_name|domain_name|fqdn|login|uuid)
  #   check_deleted - boolean to toggle searching Applications or Usage
  #
  # Returns: AppInfo or Array of AppInfo
  #
  def self.get(query, qtype, check_deleted=false)
    if check_deleted
      line, method = __LINE__, "get_deleted_by_#{qtype}"
    else
      line, method = __LINE__, "get_by_#{qtype}"
    end

    # call appropriate query method based on query type
    if query =~ /^\/.*\/$/
      if qtype == 'fqdn'
        abort 'Regexp-based FQDN queries not currently supported. Try --app or --domain instead.'
      end
      return eval("#{method}(#{query})", binding, __FILE__, line)
    else
      return eval("#{method}('#{query}')", binding, __FILE__, line)
    end
  end

  #
  # Returns: Array of AppInfo
  #
  def self.get_by_app_name(appname)
    retval = []

    Application.where(name: appname).each { |app|
      retval.concat(_domain_user_loop(app))
    }
    return retval
  end

  #
  # Returns: Array of AppInfo
  #
  def self.get_by_domain_name(namespace)
    retval = []

    Domain.where(namespace: namespace).each { |domain|
      CloudUser.where(id: domain.owner_id).each { |user|
        Application.where(domain_id: domain.id).each { |app|
          retval << AppInfo.new(user, domain, app)
        }
      }
    }
    return retval
  end

  #
  # Returns: AppInfo
  #
  def self.get_by_fqdn(fqdn)
    fqdn.match(AppQuery::FQDN_REGEX)
    app_name  = $2
    namespace = $3
    retval    = []

    Domain.where(namespace: namespace).each { |domain|
      CloudUser.where(id: domain.owner_id).each { |user|
        Application.where(domain_id: domain.id, name: app_name).each { |app|
          retval << AppInfo.new(user, domain, app)
        }
      }
    }
    return retval
  end

  #
  # Returns: Array of AppInfo
  #
  def self.get_by_login(login)
    retval = []

    CloudUser.where(login: CloudUser.normalize_login(login)).each { |user|
      user.domains.each { |domain|
        Application.where(domain_id: domain.id).each { |app|
          retval << AppInfo.new(user, domain, app)
        }
      }
    }
    return retval
  end

  #
  # Returns: AppInfo
  #
  def self.get_by_uuid(uuid)
    retval = []

    # two different ways to lookup uuids. oh joy.
    apps,gear = Application.find_by_gear_uuid(uuid)
    apps      = Application.where(uuid: uuid) unless apps

    # with two lookup methods comes two possible outputs...
    if apps.respond_to? :each
      apps.each { |app|
        retval = _domain_user_loop(app)
      }
    else
      retval = _domain_user_loop(apps)
    end

    return retval
  end

  #
  # Returns: Array of AppInfo
  #
  def self.get_deleted_by_app_name(appname)
    retval       = []
    current_apps = Application.where(name: appname).collect { |app| app.name } || Array.new
    seen_apps    = Hash.new(0)

    Usage.where(app_name: appname).each { |usage|
      next if current_apps.include? usage.app_name
      next if seen_apps.keys.include? usage.app_name

      CloudUser.where(id: usage.user_id).each { |user|
        Domain.where(owner_id: usage.user_id).each { |domain|
          retval << reconstruct(usage, user, domain)
          seen_apps[usage.app_name] += 1
        }
      }
    }
    return retval
  end

  #
  # Returns: Array of AppInfo
  #
  def self.get_deleted_by_domain_name(namespace)
    retval = []

    Domain.where(namespace: namespace).each { |domain|
      current_apps = Application.where(domain_id: domain.id).collect { |app| app.name } || Array.new
      seen_apps    = Hash.new(0)

      CloudUser.where(id: domain.owner_id).each { |user|
        Usage.where(user_id: user.id).each { |usage|
          next if current_apps.include? usage.app_name
          next if seen_apps.keys.include? usage.app_name
          retval << reconstruct(usage, user, domain)
          seen_apps[usage.app_name] += 1
        }
      }
    }
    return retval
  end

  #
  # Returns: AppInfo
  #
  def self.get_deleted_by_fqdn(fqdn)
    retval = []

    fqdn.match(AppQuery::FQDN_REGEX)
    app_name  = $2
    namespace = $3

    Domain.where(namespace: namespace).each { |domain|
      current_apps = Application.where(domain_id: domain.id).collect { |app| app.name } || Array.new
      seen_apps    = Hash.new(0)

      CloudUser.where(id: domain.owner_id).each { |user|
        Usage.where({user_id: user.id, app_name: app_name}).each { |usage|
          next if current_apps.include? usage.app_name
          next if seen_apps.keys.include? usage.app_name
          retval << reconstruct(usage, user, domain)
          seen_apps[usage.app_name] += 1
        }
      }
    }
    return retval
  end

  #
  # Returns: Array of AppInfo
  #
  def self.get_deleted_by_login(login)
    retval = []

    CloudUser.where(login: CloudUser.normalize_login(login)).each { |user|
      user.domains.each { |domain|
        current_apps = Application.where(domain_id: domain.id).collect { |app| app.name } || Array.new
        seen_apps    = Hash.new(0)

        Usage.where(user_id: user.id).each { |usage|
          next if current_apps.include? usage.app_name
          next if seen_apps.keys.include? usage.app_name
          retval << reconstruct(usage, user, domain)
          seen_apps[usage.app_name] += 1
        }
      }
    }
    return retval
  end

  #
  # Returns: AppInfo
  #
  def self.get_deleted_by_uuid(uuid)
    retval = []

    Usage.where(gear_id: uuid).each { |usage|
      CloudUser.where(id: usage.user_id).each { |user|
        Domain.where(owner_id: usage.user_id).each { |domain|
          retval << reconstruct(usage, user, domain)
        }
      }
    }
    return retval
  end

  #
  # Purpose: mock up the app structure, because there isn't one.
  # Returns: Mocked AppInfo for deleted app.
  #
  def self.reconstruct(usage, user, domain)
    dummy  = Struct.new(:name, :uuid, :created_at, :group_instances)
    app    = dummy.new(usage.app_name, usage.gear_id, usage.created_at, Array.new)
    return AppInfo.new(user, domain, app)
  end

  # helper function to reduce duplicated code.
  def self._domain_user_loop(app)
    ret = []
    Domain.where(id: app.domain_id).each { |domain|
      CloudUser.where(id: domain.owner_id).each { |user|
        ret << AppInfo.new(user, domain, app)
      }
    }
    return ret
  end

  def self.get_silver_apps()
    retval = []
    CloudUser.where({'plan_id' => /silver/}).each do |user|
      user.domains.each do |domain|
        Application.where(domain_id: domain.id).each do |app|
          retval << AppInfo.new(user, domain, app)
        end
      end
    end
    return retval
  end
end

