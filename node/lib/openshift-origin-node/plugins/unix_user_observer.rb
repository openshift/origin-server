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
        out,err,rc = shellCmd("service os-cgroups startuser #{user.name} > /dev/null")
        raise OpenShift::UserCreationException.new("Unable to setup cgroups for #{user.name}: stdout -- #{out} stderr --#{err}}") unless rc == 0
      end
    end

    def before_initialize_homedir(user)
    end

    def after_initialize_homedir(user)
    end


    def before_unix_user_destroy(user)
      out,err,rc = shellCmd("service cgconfig status > /dev/null")
      if rc == 0
        shellCmd("service os-cgroups stopuser #{user.name} > /dev/null")
      end

      last_access_dir = OpenShift::Config.instance.get("LAST_ACCESS_DIR")
      shellCmd("rm -f #{last_access_dir}/#{user.name} > /dev/null")

    end

    def before_initialize_stickshift_proxy(user)
    end

    def after_initialize_stickshift_proxy(user)
    end

    def after_unix_user_destroy(user)
    end

    def before_add_ssh_key(user,key)
    end

    def after_add_ssh_key(user,key)
      ssh_dir = File.join(user.homedir, ".ssh")
      cmd = "restorecon -R #{ssh_dir}"
      shellCmd(cmd)
    end

    def before_remove_ssh_key(user,key)
    end

    def after_remove_ssh_key(user,key)
    end
  end

  OpenShift::UnixUser.add_observer(UnixUserObserver.instance)
end
