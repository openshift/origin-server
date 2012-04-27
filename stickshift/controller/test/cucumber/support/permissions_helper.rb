require 'etc'

module PermissionHelper
  # Public: Check that some file matches target mode.
  #
  # file_path - The String path to check.
  # target_mode - The String mode that should match.
  #
  # Examples
  #
  #   mode?('/var/lib/stickshift/.blah/', '40755')
  #   # => true 
  #
  #   mode?('/etc/passwd', '100644')
  #   # => true
  #
  # Returns true if the mode matches or nil if it does not.
  def mode?(file_path, target_mode)
    actual_mode = File.stat(file_path).mode.to_s(8)
    $logger.debug("MODE_CHECK: #{file_path}: #{actual_mode}, expected: #{target_mode}")
    return true if actual_mode == target_mode
  end
  
  
  # Public: Check that some file matches target selinux context.
  #
  # file_path - The String path to check.
  # target_context - The String context that should match.
  #
  # Examples
  #
  #   context?("/var/lib/stickshift/#{uuid}/.pearrc", 
  #           "unconfined_u:object_r:libra_var_lib_t:#{mcs}")
  #   # => true 
  #
  # Returns true if the context matches or nil if it does not.
  def context?(file_path, target_context)
    actual_context = `/usr/bin/stat -c %C #{file_path}| /usr/bin/head -n1`.chomp
    $logger.debug(
      "LABEL_CHECK: #{file_path}: #{actual_context}, expected: #{target_context}"
      )
    return true if actual_context == target_context
  end
  
  # Public: Check that some file matches target owner and group
  #
  # file_path - The String path to check.
  # owner_uid - The Integer value for the user id.
  # group_gid - The Integer value for the group
  #
  # Examples
  #
  #   owner?("/etc/passwd", 0, 0)
  #   # => true 
  #
  # Returns true if the owner_uid and group_gid matches or nil if they do not.
  def owner?(file_path, owner_uid, group_gid)
    stat = File.stat(file_path)
    $logger.debug("OWNER_CHECK: #{file_path}: #{stat.uid}.#{stat.gid}, expected: #{owner_uid}.#{group_gid}")
    return true if (stat.uid == owner_uid and stat.gid == group_gid)
  end
  
  # Public: Convert uid into MCS label
  #
  # uid - The Integer value for a given user
  #
  # Examples
  #
  #   libra_mcs_level(501)
  #   # => "s0:c0,c501"
  #
  # Returns the String representation of the mcs label (selinux range).
  def libra_mcs_level(uid)
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
end

World(PermissionHelper)
