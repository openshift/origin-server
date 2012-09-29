# -*- coding: utf-8 -*-
# Copyright © 2011 Red Hat, Inc. All rights reserved

# This copyrighted material is made available to anyone wishing to use, modify,
# copy, or redistribute it subject to the terms and conditions of the GNU
# General Public License v.2.  This program is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY expressed or implied, including the
# implied warranties of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.  You should have
# received a copy of the GNU General Public License along with this program;
# if not, write to the Free Software Foundation, Inc., 51 Franklin Street,
# Fifth Floor, Boston, MA 02110-1301, USA. Any Red Hat trademarks that are
# incorporated in the source code or documentation are not subject to the GNU
# General Public License and may only be used or replicated with the express
# permission of Red Hat, Inc.

require 'rubygems'
require 'singleton'
require 'stickshift-node/config'
require 'stickshift-node/model/unix_user'
require 'stickshift-node/utils/shell_exec'

module StickShift
  class UnixUserObserver
    include StickShift::Utils::ShellExec
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
        out,err,rc = shellCmd("service libra-cgroups startuser #{user.name} > /dev/null")
        raise StickShift::UserCreationException.new("Unable to setup cgroups for #{user.name}") unless rc == 0
      end

      out,err,rc = shellCmd("service libra-tc status > /dev/null 2>&1")
      if rc == 0
        shellCmd("service libra-tc startuser #{user.name} > /dev/null")
        raise StickShift::UserCreationException.new("Unable to setup tc for #{user.name}") unless rc == 0
      end
    end

    def before_initialize_homedir(user)
    end

    def after_initialize_homedir(user)
      cmd = "/bin/sh #{File.join('/usr/libexec/stickshift/lib', "express/setup_pam_fs_limits.sh")} #{user.name} #{user.quota_blocks ? user.quota_blocks : ''} #{user.quota_files ? user.quota_files : ''}"
      out,err,rc = shellCmd(cmd)
      raise StickShift::UserCreationException.new("Unable to setup pam/fs limits for #{user.name}") unless rc == 0
    end


    def before_unix_user_destroy(user)
      out,err,rc = shellCmd("service libra-tc status #{user.name} > /dev/null 2>&1")
      if rc == 0
        shellCmd("service libra-tc stopuser #{user.name} > /dev/null")
      end

      out,err,rc = shellCmd("service cgconfig status > /dev/null")
      if rc == 0
        shellCmd("service libra-cgroups stopuser #{user.name} > /dev/null")
      end

      last_access_dir = StickShift::Config.instance.get("LAST_ACCESS_DIR")
      shellCmd("rm -f #{last_access_dir}/#{user.name} > /dev/null")

      cmd = "/bin/sh #{File.join("/usr/libexec/stickshift/lib", "express/teardown_pam_fs_limits.sh")} #{user.name}"
      shellCmd(cmd)
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

  StickShift::UnixUser.add_observer(UnixUserObserver.instance)
end
