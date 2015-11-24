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

    def get_monitor_names
    end

    def create_monitor monitor_name, path, up_code, type, interval, timeout
    end

    def delete_monitor monitor_name, type
    end

    def add_pool_monitor pool_name, monitor_name
    end

    def delete_pool_monitor pool_name, monitor_name
    end

    def get_pool_monitors pool_name
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
      fname = "#{@confdir}/alias_#{URI.escape(pool_name)}_#{URI.escape(alias_str)}.conf"
      File.unlink(fname) if File.exist?(fname)
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
        # Nothing to do;
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
        # Nothing to do;
      end
      crt = "#{@confdir}/#{URI.escape(alias_str)}.crt"
      key = "#{@confdir}/#{URI.escape(alias_str)}.key"
      File.unlink(crt) if File.exist?(crt)
      File.unlink(key) if File.exist?(key)
    end

    def update
      `service #{@nginx_service} reload`
    end

    def initialize logger, cfgfile
      @logger = logger

      @logger.info 'Initializing nginx model...'

      read_config cfgfile

      fname = "#{@confdir}/server.conf"
      unless File.exist?(fname)
        frontend_server_template = ERB.new(FRONTEND_SERVER)
        server = frontend_server_template.result(binding)

        File.write(fname, server)
      end
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
    proxy_set_header Host $host;
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
    proxy_set_header Host $host;
    <%= @health_check %>
  }
}
}

    FRONTEND_SERVER = %q{
<% if @ssl_cert and @ssl_key %>
ssl_certificate <%= @ssl_cert %>;
ssl_certificate_key <%= @ssl_key %>;
<% end %>

<% if @nginx_plus %>
match statusok {
  status <%= @health_check_match_status %>;
}
<% end %>

server {
  listen <%= @http_port %> default_server;
  server_name _;
  location / {
    return 404;
  }
}

server {
  listen <%= @ssl_port %> ssl default_server;
  server_name _;
  location / {
    return 404;
  }
}

}

  end

end
