#!/usr/bin/ruby

require 'rubygems'
require 'rest-client'
require 'openshift-origin-node'
require 'pp'
require 'json'

#$create_url='curl -k -X POST -H "Accept: application/xml" --user "%s:%s" https://%s/broker/rest/domains/%s/applications'
#$scale_url="#{$create_url}/%s/events"

$base_url='https://%s/broker/rest'
$create_url='/domains/%s/applications'
$scale_url='/domains/%s/applications/%s/events'
$cartridges_url='/cartridges'
$domain_url='/domains'

class Gear_scale_ctl
  def initialize(action, opts)
    if action ==  'gear-scale-ctl.rb'
      $stderr.puts 'Call gear-scale-ctl via an alias: add-gear, remove-gear'
      exit 2
    end

    if not ['add-gear', 'remove-gear'].include? action
      usage opts
    end

    @action = action
    @opts = opts

    base_url = "#{$base_url % opts["server"]}#{$scale_url % [opts['namespace'], opts['app']]}"
    params = {
        'broker_auth_key' => File.read("/var/lib/openshift origin/#{opts['uuid']}/.auth/token"),
        'broker_auth_iv' => File.read("/var/lib/openshift origin/#{opts['uuid']}/.auth/iv")
    }
    return if not check_scalability(params, action, opts)

    params['event'] = 'add-gear' == action ?  'scale-up' : 'scale-down'

    request = RestClient::Request.new(:method => :post, :url => base_url, :timeout => 600,
        :headers => {:accept => 'application/json', :user_agent => 'OpenShift'},
        :payload => params
        )

    begin
      response = request.execute()
      if 300 <= response.code
        raise response
      end
    rescue RestClient::UnprocessableEntity => e
      if action == "add-gear"
        puts "Already at the maximum number of gears allowed for either the app or your account."
      elsif action == "remove-gear"
        puts "Already at the minimum number of gears required for this application."
      else
        puts "The #{action} request could not be processed."
      end
      return false
    rescue RestClient::ExceptionWithResponse => e
      $stderr.puts "The #{action} request failed with http_code: #{e.http-code}"
      return false
    rescue RestClient::Exception => e
      $stderr.puts "The #{action} request failed with the following exception: #{e.to_s}"
      return false
    end
  end

  def check_scalability(params, action, opts)
    env = load_env(opts)
    data_dir = env['OPENSHIFT_DATA_DIR']
    scale_file = "#{data_dir}/scale_limits.txt"
    min = 1
    max = -1
    if not File.exists? scale_file
      gear_info_url = "#{$base_url % opts["server"]}#{$create_url % opts['namespace']}/#{opts['app']}"
      request = RestClient::Request.new(:method => :get, :url => gear_info_url, :timeout => 120,
          :headers => {:accept => 'application/json', :user_agent => 'OpenShift'},
          :payload => params
          )

      begin
        response = request.execute()
        if 300 <= response.code
          return false
        end
      rescue RestClient::Exception => e
        $stderr.puts "Failed to get application info from the broker."
        return false
      end

      begin
        response_object = JSON.parse(response)
        min = response_object["data"]["scale_min"]
        max = response_object["data"]["scale_max"]
      rescue
        $stderr.puts "Could not use the application info response."
        return false
      end

      f = File.open(scale_file, 'w')
      f.write("scale_min=#{min}\nscale_max=#{max}")
      f.close
    else

      begin
        scale_data = File.read(scale_file)
        scale_hash = {}
        scale_data.split("\n").each { |s|
          line = s.split("=")
          scale_hash[line[0]] = line[1]
        }
        min = scale_hash["scale_min"].to_i
        max = scale_hash["scale_max"].to_i
      rescue => e
        $stderr.puts "Could not read or parse #{scale_file}"
        begin
          # Get it fresh from the broker next invocation
          File.unlink(scale_file)
        rescue
        end
        return false
      end
    end

    haproxy_conf_dir=File.join(env['OPENSHIFT_HOMEDIR'], "haproxy-1.4", "conf")
    gear_registry_db=File.join(haproxy_conf_dir, "gear-r