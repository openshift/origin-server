#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++
require 'rubygems'
require 'erb'
require 'openshift-origin-common'
require_relative '../../openshift-origin-node/utils/shell_exec'
require_relative '../../openshift-origin-node/model/unix_user'

module OpenShift

  ##
  # This class represents an Application's Git repository

  class ApplicationRepository
    include OpenShift::Utils

    attr_reader :path

    ##
    # Creates a new application Git repository from a template
    #
    # +user+ is of type +UnixUser+
    def initialize(user)
      @user   = user
      @path   = File.join(@user.homedir, 'git', "#{@user.app_name}.git")
      @config = OpenShift::Config.new
    end

    ##
    # +populate_from_cartridge+ uses the provided +cartridge_name+ to install a template application
    # for the gear
    #
    # If the directory +template+ exists it will be installed in the application's repository.
    # If the directory +template.git+ exists it will be cloned as the application's repository.
    #
    def populate_from_cartridge(cartridge_name)
      FileUtils.mkpath(File.join(@user.homedir, 'git'))

      cartridge_template     = File.join(@user.homedir, cartridge_name, 'template')
      cartridge_template_git = File.join(@user.homedir, cartridge_name, 'template.git')

      have_template = (File.exist? cartridge_template or File.exist? cartridge_template_git)

      raise ArgumentError.new(
                "No template for application git repository found"
            ) unless have_template

      # TODO: Support tar balls etc...
      raise NotImplementedError.new(
                "#{File.join(cartridge_name, 'template')}: files are not support for initializing a git repository"
            ) if File.file? cartridge_template

      # expose variables for ERB processing
      @application_name = @user.app_name
      @cartridge_name   = cartridge_name

      # FIXME: See below
      @broker_host      = @config.get('BROKER_HOST')

      case
        when File.exists?(cartridge_template)
          pull_directory(cartridge_template)
        when File.exist?(cartridge_template_git)
          pull_bare_repository(cartridge_template_git)
      end
      configure_repository
    end

    ##
    # Copy bare git repository to be used as application repository
    def pull_bare_repository(path)
      FileUtils.cp_r(path, @path)
    end

    ##
    # Copy a file tree structure and build an application repository
    def pull_directory(path)
      template = File.join(@user.homedir, 'git', 'template')
      FileUtils.rm_r(template) if File.exist? template

      git_path = File.join(@user.homedir, 'git')
      FileUtils.cp_r(path, git_path)

      Utils.oo_spawn(ERB.new(GIT_INIT).result(binding),
                     chdir:               template,
                     expected_exitstatus: 0)
      begin
        # trying to clone as the user proved to be painful as git managed to "loose" the selinux context
        Utils.oo_spawn(ERB.new(GIT_LOCAL_CLONE).result(binding),
                       chdir:               git_path,
                       expected_exitstatus: 0)
      rescue ShellExecutionException => e
        FileUtils.rm_r(@path) if File.exits? @path

        raise ShellExecutionException.new(
                  'Failed to clone application git repository from template repository',
                  e.rc, e.stdout, e.stderr)
      else
        configure_repository()
      ensure
        FileUtils.rm_r(template)
      end
    end

    ##
    # Install Git repository hooks and set permissions
    def configure_repository
      UnixUser.match_ownership(@user.homedir, @path)

      # application developer cannot change git hooks
      hooks = File.join(@path, 'hooks')
      FileUtils.chown_R(0, 0, hooks)

      render_file = lambda { |f, m, t|
        File.open(f, 'w', m) { |f| f.write(ERB.new(t).result(binding)) }
      }

      render_file.call(File.join(@path, 'description'), 0644, GIT_DESCRIPTION)
      render_file.call(File.join(@user.homedir, '.gitconfig'), 0644, GIT_CONFIG)

      render_file.call(File.join(hooks, 'pre-receive'), 0755, PRE_RECEIVE)
      render_file.call(File.join(hooks, 'post-receive'), 0755, POST_RECEIVE)
    end

    private
    #-- ERB Templates -----------------------------------------------------------

    GIT_INIT = %Q{\
set -xe;
git init;
git config user.email "builder@example.com";
git config user.name "Template builder";
git add -f .;
git </dev/null commit -a -m "Creating template"
}

    GIT_LOCAL_CLONE = %Q{\
set -xe;
git </dev/null clone --bare --no-hardlinks template <%= @application_name %>.git;
GIT_DIR="./<%= @application_name %>.git" git repack
}

    GIT_DESCRIPTION = %Q{\
<%= @cartridge_name %> application <%= @application_name %>
}

    GIT_CONFIG = %Q{\
[user]
  name = OpenShift System User
[gc]
  auto = 100
}

    LOAD_ENV = %Q{\
# Import Environment Variables
for f in /etc/openshift/env/* ~/.env/* ~/*-*/env/*
do
  [ -f $f ] && . $f
done
}

    PRE_RECEIVE  = %Q{\
#!/bin/bash

<%= LOAD_ENV %>

pre_receive_app.sh
}

    # FIXME: Broker host should not be defined here, rather nuture script should look it up
    # currently broker_host is tagged at the end of all the build scripts. Kinda like an egg race!
    POST_RECEIVE = %Q{\
#!/bin/bash

<%= LOAD_ENV %>

post_receive_app.sh <%= @broker_host %>
}
  end
end
