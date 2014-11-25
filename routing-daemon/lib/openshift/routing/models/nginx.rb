require 'openshift/routing/models/load_balancer'

require 'erb'
require 'parseconfig'
require 'uri'

module OpenShift

  # == Load-balancer model class for the F5 BIG-IP LTM load balancer.
  #
  # Presents direct access to an F5 BIG-IP LTM load balancer using the
  # iControl REST interface.
  #
  class NginxLoadBalancerModel < LoadBalancerModel

    def read_config cfgfile
      cfg = ParseConfig.new(cfgfile)

      @confdir = cfg['NGINX_CONFDIR']
      @nginx_service = cfg['NGINX_SERVICE']
      @ssl_port = cfg['SSL_PORT']
      @ssl_cert = cfg['NGINX_SSL_CERTIFICATE']
      @ssl_key = cfg['NGINX_SSL_KEY']
      @http_port = cfg['HTTP_PORT']
      @nginx_plus = cfg['NGINX_PLUS'] == 'true'
      health_check_interval = cfg['NGINX_PLUS_HEALTH_CHECK_INTERVAL']
      health_check_fails = cfg['NGINX_PLUS_HEALTH_CHECK_FAILS']
      health_check_passes = cfg['NGINX_PLUS_HEALTH_CHECK_PASSES']
      health_check_uri = cfg['NGINX_PLUS_HEALTH_CHECK_URI']
      @health_check_shared_memory = cfg['NGINX_PLUS_HEALTH_CHECK_SHARED_MEMORY']
      @health_check_match_status = cfg['NGINX_PLUS_HEALTH_CHECK_MATCH_STATUS']
      @health_check = @nginx_plus ? "health_check interval=#{health_check_interval} fails=#{health_check_fails} passes=#{health_check_passes} uri=#{health_check_uri} match=statusok;" : ""
      pool_name_format = cfg['POOL_NAME'] || 'pool_ose_%a_%n_80'
      @pool_fname_regex = Regexp.new("\\A(#{pool_name_format.gsub(/%./, '.*')})\\.conf\\Z")
    end

    # We manage the backend configuration by having one file per pool.  This
    # simplifies the creation, manipulation, and deletion of pools because we
    # eliminate (in the case of creation and deletion) or at least reduce (in
    # the case of manipulation) the amount of parsing we need to do to update
    # the configuration files.

    # get_pool_names :: [String]
    def get_pool_names
      pool_names = []
      Dir.entries(@confdir).each do |entry|
        pool_names.push $1 if entry =~ @pool_fname_regex
      end
      pool_names
    end

    def create_pool pool_name, monitor_name
      # Write an empty file rather than an empty "upstream" clause
      # because nginx doesn't like the latter.
      File.write("#{@confdir}/#{pool_name}.conf", '')
    end

    def delete_pools pool_names
      File.unlink(*pool_names.map {|n| "#{@confdir}/#{n}.conf"})
    end

    # Although it would be much easier to manage the frontend configuration by
    # using one .conf file per route (the way we use one file per alias, or the
    # way we manage the backend configuration by having one file per pool),
    # nginx does not allow multiple server {} clauses for the same virtual
    # server, which means we cannot split the configuration into separate files.

    def get_route_names
      routes = []
      begin
        File.open("#{@confdir}/server.conf").each_line do |line|
          routes.push $1 if line =~ /\A\s*#\s*route_name\s*=\s*(\S+)\s*\Z/
        end
      rescue Errno::ENOENT
        # Nothing to do; if server.conf doesn't exist, then that means
        # there are no routes, so we should just return the empty array.
      end
      routes
    end

    alias_method :get_active_route_names, :get_route_names

    def create_routes pool_names, routes
      fname = "#{@confdir}/server.conf"

      location_template        = ERB.new(FRONTEND)
      frontend_server_template = ERB.new(FRONTEND_SERVER)

      route_name = nil
      path = nil
      begin
        File.open(fname).each_line do |line|
          if line =~ /\A\s*#\s*route_name\s*=\s*(\S+)\s*\Z/
            route_name = $1
            next
          end

          if line =~ /\A\s*location\s*(\S+)\s*{\s*\Z/
            path = $1
            next
          end

          if line =~ /\A\s*proxy_pass\s*http:\/\/(\S+)\s*;\s*\Z/
            raise LBModelException.new "Error parsing server.conf" unless route_name && path
            pool_names.push $1 unless pool_names.include? $1
            routes.push [route_name, path]
            route_name = nil
            path = nil
          end
        end
      rescue Errno::ENOENT
        # Nothing to do; if server.conf doesn't exist, then that means
        # there are no routes, so we should just return the empty array.
      end

      locations = pool_names.zip(routes).map do |pool_name, (route_name, path)|
        location_template.result(binding)
      end.join

      server = frontend_server_template.result(binding)

      File.write(fname, server)
    end

    def attach_routes route_names, virtual_server_names
      # no-op
    end

    def detach_routes route_names, virtual_server_names
      # no-op
    end

    def delete_routes delete_pool_names, delete_route_names
      fname = "#{@confdir}/server.conf"

      location_template        = ERB.new(FRONTEND)
      frontend_server_template = ERB.new(FRONTEND_SERVER)

      ### Read in old configuration.

      pool_names = []
      routes = []

      route_name = nil
      path = nil
      File.open(fname).each_line do |line|
        if line =~ /\A\s*#\s*route_name\s*=\s*(\S+)\s*\Z/
          route_name = $1
          next
        end

        if line =~ /\A\s*location\s*(\S+)\s*{\s*\Z/
          path = $1
          next
        end

        if line =~ /\A\s*proxy_pass\s*http:\/\/(\S+)\s*;\s*\Z/
          raise LBModelException.new "Error parsing server.conf" unless route_name && path

          # Filter out the entries we want to delete.
          unless delete_route_names.include?(route_name)
            pool_names.push $1 unless pool_names.include? $1
            routes.push [route_name, path]
          end
          route_name = nil
          path = nil
        end
      end

      ### Write out the old configuration.

      locations = pool_names.zip(routes).map do |pool_name, (route_name, path)|
        location_template.result(binding)
      end.join

      server = frontend_server_template.result(binding)

      File.write(fname, server)
    end

    def get_monitor_names
    end

    def create_monitor monitor_name, path, up_code, type, interval, timeout
    end

    def delete_monitor monitor_name
    end

    def get_pool_members pool_name
      begin
        fname = "#{@confdir}/#{pool_name}.conf"
        members = []
        File.open(fname).each_line do |line|
          members.push $1 if line =~ /\A\s*server\s+(\S+)\s*;\Z/
        end
        members
      rescue Errno::ENOENT
        raise LBModelException.new "Pool not found: #{pool_name}"
      end
    end

    alias_method :get_active_pool_members, :get_pool_members

    def add_pool_members pool_names, member_lists
      backend_template        = ERB.new(BACKEND)
      backend_server_template = ERB.new(BACKEND_SERVER)

      pool_names.zip(member_lists).each do |pool_name, members|
        members.push *get_pool_members(pool_name).map {|m| m.split(':')}
        servers = members.inject('') do |str, (address, port)|
          str + backend_server_template.result(binding)
        end

        fname = "#{@confdir}/#{pool_name}.conf"
        File.write(fname, backend_template.result(binding))
      end
    end

    def delete_pool_members pool_names, member_lists
      backend_template        = ERB.new(BACKEND)
      backend_server_template = ERB.new(BACKEND_SERVER)

      pool_names.zip(member_lists).each do |pool_name, delete_members|
        delete_members_ = delete_members.map {|address, port| address + ':' + port.to_s}
        servers = get_pool_members(pool_name).
          reject {|member| delete_members_.include?(member)}.
          map {|member| member.split(':')}.
          map {|address, port| backend_server_template.result(binding)}.
          join

        fname = "#{@confdir}/#{pool_name}.conf"
        File.write(fname, backend_template.result(binding))
      end
    end

    def get_pool_aliases pool_name
      alias_fname_regex = Regexp.new("\\Aalias_#{pool_name}_(.*)\\.conf\\Z")

      aliases = []
      Dir.entries(@confdir).each do |entry|
        aliases.push URI.unescape($1) if entry =~ alias_fname_regex
      end
      aliases.uniq
    end

    def add_pool_alias pool_name, alias_str
      frontend_alias_template = ERB.new(FRONTEND_ALIAS)
      fname = "#{@confdir}/alias_#{URI.escape(pool_name)}_#{URI.escape(alias_str)}.conf"
      File.write(fname, frontend_alias_template.result(binding))
    end

    def delete_pool_alias pool_name, alias_str
      File.unlink("#{@confdir}/alias_#{URI.escape(pool_name)}_#{URI.escape(alias_str)}.conf")
    end

    def get_pool_certificates pool_name
      pool_certs = []
      aliases = get_pool_aliases pool_name
      aliases.each do |alias_str|
        fname = "#{@confdir}/alias_#{URI.escape(pool_name)}_#{URI.escape(alias_str)}.conf"
        text = File.read(fname)
        pool_certs << alias_str if text.scan(/^.*(ssl_certificate)$/).count > 0
      end
    end

    def add_ssl pool_name, alias_str, ssl_cert, private_key
      certfname = "#{@confdir}/#{URI.escape(alias_str)}.crt"
      keyfname = "#{@confdir}/#{URI.escape(alias_str)}.key"
      fname = "#{@confdir}/alias_#{URI.escape(pool_name)}_#{URI.escape(alias_str)}.conf"

      File.write(certfname, ssl_cert)
      File.write(keyfname, private_key)
      begin
        text = File.read(fname)
        new_text = text.gsub(/^.*#ssl_certificate_template$/, "ssl_certificate #{certfname};")
        new_text = new_text.gsub(/^.*#ssl_certificate_key_template$/, "ssl_certificate_key #{keyfname};")
        @logger.debug("#{new_text}")
        @logger.debug("Adding SSL configuration for alias #{alias_str} for pool #{pool_name}")
        File.open(fname, "w") {|file| file.puts new_text }
      rescue Errno::ENOENT
        # Nothing to do; if server.conf doesn't exist, then that means
        # there are no routes, so we should just return the empty array.
      end
    end

    def remove_ssl pool_name, alias_str
      fname = "#{@confdir}/alias_#{URI.escape(pool_name)}_#{URI.escape(alias_str)}.conf"
      begin
        text = File.read(fname)
        new_text = text.gsub(/^.*ssl_certificate_key\s*.*key;$/, "  #ssl_certificate_key_template")
        new_text = new_text.gsub(/^.*ssl_certificate\s*.*crt;$/, "  #ssl_certificate_template")
        @logger.debug("Removing SSL configuration for alias #{alias_str} for pool #{pool_name}")
        File.open(fname, "w") {|file| file.puts new_text }
      rescue Errno::ENOENT
        # Nothing to do; if server.conf doesn't exist, then that means
        # there are no routes, so we should just return the empty array.
      end
      File.unlink("#{@confdir}/#{URI.escape(alias_str)}.crt")
      File.unlink("#{@confdir}/#{URI.escape(alias_str)}.key")
    end

    def update
      `service #{@nginx_service} reload`
    end

    def initialize logger, cfgfile
      @logger = logger

      @logger.info 'Initializing nginx model...'

      read_config cfgfile
    end

    # ERB Templates

    BACKEND_SERVER = %q{
  server <%= address %>:<%= port %>;
}

    BACKEND = %q{
upstream <%= pool_name %> {
<% if @nginx_plus %>
 zone <%= pool_name %> <%= @health_check_shared_memory %>;
<% end %>
 <%= servers %>
}
}

    FRONTEND_ALIAS = %q{
server {
  listen <%= @http_port %>;
  server_name <%= alias_str %>;
  location / {
    proxy_pass http://<%= pool_name %>;
    <%= @health_check %>
  }
}

server {
  listen <%= @ssl_port %> ssl;
  #ssl_certificate_template
  #ssl_certificate_key_template
  server_name <%= alias_str %>;
  location / {
    proxy_pass http://<%= pool_name %>;
    <%= @health_check %>
  }
}
}

    FRONTEND_SERVER = %q{
<% if @ssl_cert and @ssl_key %>
ssl_certificate <%= @ssl_cert %>;
ssl_certificate_key <%= @ssl_key %>;
<% end %>
server {
  listen <%= @http_port %>;
  <%= locations %>
}
<% if @nginx_plus %>
match statusok {
  status <%= @health_check_match_status %>;
}
<% end %>

server {
  listen <%= @ssl_port %> ssl;
  <%= locations %>
}
<% if @nginx_plus %>
match statusok {
  status <%= @health_check_match_status %>;
}
<% end %>

}

    FRONTEND = %q{
  # route_name=<%= route_name %>
  location <%= path %> {
    proxy_pass http://<%= pool_name %>;
    <%= @health_check %>
  }
}

  end

end
