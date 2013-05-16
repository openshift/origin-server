
require 'rubygems'
require 'singleton'
require 'openshift-origin-node/config'
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/utils/shell_exec'

module OpenShift
  class UnixUserObserver
    include OpenShift::Utils::ShellExec
    include Object::Singleton

    def update(*args)
      method = args.first
      args = args.drop(1)
      send(method, *args)
    end

    def before_unix_user_create(user)
    end

    def after_unix_user_create(user)
      out,err,rc = shellCmd("service cgconfig status > /dev/null 2>&1")
      if rc == 0
        out,err,rc = shellCmd("/usr/sbin/oo-admin-ctl-cgroups startuser #{user.name} > /dev/null")
        raise OpenShift::UserCreationException.new("Unable to setup cgroups for #{user.name}: stdout -- #{out} stderr --#{err}}") unless rc == 0
      end
    end

    def before_initialize_homedir(user)
    end

    def after_initialize_homedir(user)
      cmd = "/bin/sh #{File.join('/usr/libexec/openshift/lib', "setup_pam_fs_limits.sh")} #{user.name} #{user.quota_blocks ? user.quota_blocks : ''} #{user.quota_files ? user.quota_files : ''}"
      out,err,rc = shellCmd(cmd)
      raise OpenShift::UserCreationException.new("Unable to setup pam/fs limits for #{user.name}: stdout -- #{out} stderr -- #{err}") unless rc == 0
    end


    def before_unix_user_destroy(user)
      cmd = "/bin/sh #{File.join('/usr/libexec/openshift/lib', "setup_pam_fs_limits.sh")} #{user.name} 0 0 0"
      out,err,rc = shellCmd(cmd)
      raise OpenShift::UserCreationException.new("Unable to setup pam/fs/nproc limits for #{user.name}") unless rc == 0

      out,err,rc = shellCmd("service cgconfig status > /dev/null")
      if rc == 0
        shellCmd("/usr/sbin/oo-admin-ctl-cgroups freezeuser #{user.name} > /dev/null") if rc == 0
      end

      last_access_dir = OpenShift::Config.instance.get("LAST_ACCESS_DIR")
      shellCmd("rm -f #{last_access_dir}/#{user.name} > /dev/null")
    end

    def before_initialize_openshift_port_proxy(user)
    end

    def after_initialize_openshift_port_proxy(user)
    end

    def after_unix_user_destroy(user)
      out,err,rc = shellCmd("service cgconfig status > /dev/null")
      shellCmd("/usr/sbin/oo-admin-ctl-cgroups thawuser #{user.name} > /dev/null") if rc == 0
      shellCmd("/usr/sbin/oo-admin-ctl-cgroups stopuser #{user.name} > /dev/null") if rc == 0

      cmd = "/bin/sh #{File.join("/usr/libexec/openshift/lib", "teardown_pam_fs_limits.sh")} #{user.name}"
      out,err,rc = shellCmd(cmd)
      raise OpenShift::UserCreationException.new("Unable to teardown pam/fs/nproc limits for #{user.name}") unless rc == 0
    end

    def before_add_ssh_key(user,key)
    end

    def after_add_ssh_key(user,key)
      restore_ssh_key_file_config(user)
    end

    def before_remove_ssh_key(user,key)
    end

    def after_remove_ssh_key(user,key)
    end

    def before_replace_ssh_keys(user)
    end

    def after_replace_ssh_keys(user)
      restore_ssh_key_file_config(user)
    end
    
    def restore_ssh_key_file_config(user)
      ssh_dir = File.join(user.homedir, ".ssh")
      cmd = "restorecon -R #{ssh_dir}"
      shellCmd(cmd)
    end
  end

  OpenShift::UnixUser.add_observer(UnixUserObserver.instance)
end
