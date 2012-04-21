#!/usr/bin/ruby

require 'rubygems'
require 'rest-client'
require 'stickshift-node'
require 'pp'

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
        'broker_auth_key' => File.read("/var/lib/stickshift/#{opts['uuid']}/.auth/token"),
        'broker_auth_iv' => File.read("/var/lib/stickshift/#{opts['uuid']}/.auth/iv")
    }
    params['event'] = 'add-gear' == action ?  'scale-up' : 'scale-down'

    request = RestClient::Request.new(:method => :post, :url => base_url, :timeout => 120,
        :headers => {:accept => 'application/json', :user_agent => 'StickShift'},
        :payload => params
        )

    response = request.execute()
    if 300 <= response.code
      raise response
    end
  end
end

def usage
  $stderr.puts <<USAGE

Usage:

Add gear to application:
  Usage: add-gear -a|--app <application name> -u|--uuid <user> -n|--namespace <namespace uuid> [-h|--host <hostname>]

Remove gear from application:
  Usage: remove-gear -a|--app <application name> -u|--uuid <user> -n|--namespace <namespace uuid> [-h|--host <hostname>]

  -a|--app         application name  Name for your application (alphanumeric - max <rest call?> chars) (required)
  -u|--uuid        application uuid  UUID for your application (required)
  -n|--namespace   namespace    Namespace for your application(s) (alphanumeric - max <rest call?> chars) (required)
  -h|--host        libra server host running broker

USAGE
  exit! 255
end

config = StickShift::Config.instance

opts = {
    'server' => config.get('BROKER_HOST')
}

begin
  args = GetoptLong.new(
    ['--app',       '-a', GetoptLong::REQUIRED_ARGUMENT],
    ['--uuid',      '-u', GetoptLong::REQUIRED_ARGUMENT],
    ['--namespace', '-n', GetoptLong::REQUIRED_ARGUMENT],
    ['--server',    '-s', GetoptLong::REQUIRED_ARGUMENT]
  )

  args.each {|opt, arg| opts[opt[2..-1]] = arg.to_s}

  if 0 != ARGV.length
    usage
  end

  if opts['server'].nil? || opts['server'].empty? \
        || opts['app'].nil? || opts['app'].empty? \
        || opts['uuid'].nil? || opts['uuid'].empty? \
        || opts['namespace'].nil? || opts['namespace'].empty?
    usage
  end
rescue Exception => e
  usage
end

o = Gear_scale_ctl.new(File.basename($0), opts)

exit 0
