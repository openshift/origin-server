#!/usr/bin/ruby

require 'etc'
require 'erb'
require 'fileutils'

@UUID = ARGV[0]
@CART_TYPE = ARGV[1]

unless ARGV.count == 2
  puts "bad argv count"
  exit 3
end

# Deploy proxy config
def deploy_proxy(proxy_template)
  renderer = ERB.new(File.new(proxy_template).read, nil, "%")
  proxy_config = proxy_template.sub('.erb', '')
  File.open(config_file, 'w') { |f| f.write(renderer.result()) }
end

def get_mcs_level(uuid)
  userinfo = Etc.getpwnam(uuid)
  uid = userinfo.uid
  setsize=1023
  tier=setsize
  ord=uid
  while ord > tier
    ord -= tier
    tier -= 1
  end
  tier = setsize - tier
  "s0:c#{tier},c#{ord + tier}"
end


def observe_setup_var_lib_dir(uuid, path)
  mcs = get_mcs_level(uuid)
  `chcon -l libra_var_lib_t -l #{mcs} -R "#{path}"`
end

def observe_setup_var_lib_file(uuid, path)
  mcs = get_mcs_level(uuid)
  `chcon -l libra_var_lib_t -l #{mcs} "#{path}"`
end


# Setup Needed Variables
@HOME = File.expand_path("~#{@UUID}")
@CART_HOME = "#{@HOME}/#{@CART_TYPE}/"
@MCS = get_mcs_level(@UUID)

Dir.chdir(@HOME)

File.open("#{@CART_HOME}/metadata/root_files.txt", 'r').each_line do | path |
  path = path.strip
  next if path.end_with?('*')
  puts "Creating #{File.expand_path(path)}"
  if path.end_with?('/')
    # directory
    abs_path = File.expand_path(path)
    FileUtils.mkdir_p abs_path
    observe_setup_var_lib_dir(@UUID, abs_path)
  else
    # file
    abs_path = File.expand_path(path)
    FileUtils.mkdir_p File.dirname(abs_path)
    FileUtils.touch abs_path
    observe_setup_var_lib_file(@UUID, abs_path)
  end
  FileUtils.chown_R(@UUID, @UUID, abs_path)
end
