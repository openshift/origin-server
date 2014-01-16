require 'rubygems'
require 'rest-client'
require 'openshift-origin-node'
require 'pp'
require 'json'

$base_url='https://%s/broker/rest'
$create_url='/domains/%s/applications'
$scale_url='/domains/%s/applications/%s/events'
$cartridges_url='/cartridges'
$domain_url='/domains'

class GearScaleCtl

  attr_accessor :opts, :action

  def initialize(opts)
    @opts = opts
  end

  def add_gear
    execute('add')
  end

  def remove_gear
    execute('remove')
  end

  def execute(action)
    base_url = "#{$base_url % opts["server"]}#{$scale_url % [opts['namespace'], opts['app']]}"
    params = {
        'broker_auth_key' => File.read("/var/lib/openshift/#{opts['uuid']}/.auth/token"),
        'broker_auth_iv' => File.read("/var/lib/openshift/#{opts['uuid']}/.auth/iv")
    }
    check_scalability(params, action, opts)

    params['event'] = 'add-gear' == action ?  'scale-up' : 'scale-down'

    request = RestClient::Request.new(:method => :post, :url => base_url, :timeout => 600,
        :headers => {:accept => 'application/json', :user_agent => 'OpenShift'},
        :payload => params
        )

    begin
      response = request.execute
      if 300 <= response.code
        raise response
      end
    rescue RestClient::UnprocessableEntity => e
      if action == "add-gear"
        raise "Already at the maximum number of gears allowed for either the application or your account."
      elsif action == "remove-gear"
        raise "Already at the minimum number of gears required for this application."
      else
        raise "The #{action} request could not be processed."
      end
    rescue RestClient::ExceptionWithResponse => e
      raise "The #{action} request failed with http_code: #{e.http_code}"
    rescue RestClient::Exception => e
      raise "The #{action} request failed with the following exception: #{e.message}"
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
          :headers => {:accept => 'application/json;version=1.0', :user_agent => 'OpenShift'},
          :payload => params
          )

      begin
        response = request.execute()
        if 300 <= response.code
          raise "Invalid response code from scalability check"
        end
      rescue RestClient::Exception => e
        raise "Failed to get application info from the broker: #{e.message}"
      end

      begin
        response_object = JSON.parse(response)
        min = response_object["data"]["scale_min"]
        max = response_object["data"]["scale_max"]
      rescue
        raise "Could not use the application info response."
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
        begin
          # Get it fresh from the broker next invocation
          File.unlink(scale_file)
        rescue
        end
        raise "Could not read or parse #{scale_file}"
      end
    end

    current_gear_count = `oo-gear-registry web | wc -l`
    current_gear_count = current_gear_count.split(' ')[0].to_i

    if action=='add-gear' and current_gear_count == max
      raise "Cannot add gear because max limit '#{max}' reached."
    elsif action=='remove-gear' and current_gear_count == min
      raise "Cannot remove gear because min limit '#{min}' reached."
    end
  end

  def load_env(opts)
    env = {}
    # Load environment variables into a hash

    Dir["/var/lib/openshift/#{opts['uuid']}/.env/*"].each { | f |
      next if File.directory?(f)
      contents = nil
      File.open(f) { |input| contents = input.read.chomp }
      env[File.basename(f)] =  contents
    }
    env
  end

end