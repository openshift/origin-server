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
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/selinux'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-common/utils/path_utils'
require 'openshift-origin-common/utils/git'
require 'openshift-origin-node/utils/node_logger'

module OpenShift
  module Runtime
    ##
    # This class represents an Application's Git repository

    class ApplicationRepository
      include OpenShift::Runtime::Utils
      include NodeLogger

      attr_reader :path

      ##
      # Creates a new application Git repository from a template
      #
      # +container+ is of type +ApplicationContainer+
      def initialize(container)
        @container = container
        @path = PathUtils.join(@container.container_dir, 'git', "#{@container.application_name}.git")
      end

      def empty?
        return false unless exist?
        out, err, exitstatus = Utils.oo_spawn(COUNT_GIT_OBJECTS,
                                              chdir:               @path)
        out.strip == "0" && exitstatus == 0
      end

      def exist?
        File.directory?(@path)
      end

      alias exists? exist?

      ##
      # +populate_from_cartridge+ uses the provided +cartridge_name+ to install a template application
      # for the gear
      #
      # Template search locations:
      #   * ~/<cartridge home>/template
      #   * ~/<cartridge home>/template.git
      #   * ~/<cartridge home>/usr/template
      #   * ~/<cartridge home>/usr/template.git
      #
      # return nil if application bare repository exists or no template found
      #            otherwise path of template used
      def populate_from_cartridge(cartridge_name)
        return nil if exists?

        FileUtils.mkpath(PathUtils.join(@container.container_dir, 'git'))

        locations = [
            PathUtils.join(@container.container_dir, cartridge_name, 'template'),
            PathUtils.join(@container.container_dir, cartridge_name, 'template.git'),
            PathUtils.join(@container.container_dir, cartridge_name, 'usr', 'template'),
            PathUtils.join(@container.container_dir, cartridge_name, 'usr', 'template.git'),
        ]

        template = locations.find {|l| File.directory?(l)}
        logger.debug("Using '#{template}' to populate git repository for #{@container.uuid}")
        return nil unless template

        # expose variables for ERB processing
        @application_name = @container.application_name
        @cartridge_name   = cartridge_name

        if template.end_with? '.git'
          FileUtils.cp_r(template, @path, preserve: true)
        else
          build_bare(template)
        end

        configure
        template
      end

      ##
      # +populate_from_url+ uses the provided +cartridge_url+ to install a template application
      # for the gear
      #
      def populate_from_url(cartridge_name, url)
        return nil if exists?

        repo_spec, commit = ::OpenShift::Git.safe_clone_spec(url, ::OpenShift::Git::ALLOWED_NODE_SCHEMES) rescue \
          raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(
            "CLIENT_ERROR: The provided source code repository URL is not valid (#{$!.message})",
            130)
        unless repo_spec
          raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(
            "CLIENT_ERROR: Source code repository URL protocol must be one of: #{::OpenShift::Git::ALLOWED_NODE_SCHEMES.join(', ')}",
            130)
        end

        git_path = PathUtils.join(@container.container_dir, 'git')
        FileUtils.mkpath(git_path)

        # expose variables for ERB processing
        @application_name = @container.application_name
        @cartridge_name   = cartridge_name
        @user_homedir     = @container.container_dir
        @url              = repo_spec
        @commit           = commit

        begin
          ::OpenShift::Runtime::Utils::oo_spawn(ERB.new(GIT_URL_CLONE).result(binding),
              chdir:               git_path,
              expected_exitstatus: 0)
        rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
          if ssh_like? url
            msg = "CLIENT_ERROR: Source code repository could not be cloned: '#{url}'. Please verify the repository is correct and try a non-SSH URL such as HTTP."
          else
            msg = "CLIENT_ERROR: Source code repository could not be cloned: '#{url}'. Please verify the repository is correct and contact support."
          end
          raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(msg, 131)
        end

        configure
      end

      ##
      # +populate_empty+ initializes a default, empty Git repository
      # for the gear
      #
      def populate_empty(cartridge_name)
        return nil if exists?

        git_path = @path
        FileUtils.mkpath(git_path)

        # expose variables for ERB processing
        @application_name = @container.application_name
        @cartridge_name   = cartridge_name
        @user_homedir     = @container.container_dir

        begin
          Utils.oo_spawn(ERB.new(GIT_INIT_BARE).result(binding),
                         chdir:               git_path,
                         expected_exitstatus: 0)
        rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
          raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(
                    "CLIENT_ERROR: Source code repository could not be created.  Please contact support.",
                    131
                )
        end

        configure
      end

      def archive(destination, ref)
        return unless exist?

        # expose variables for ERB processing
        @application_name = @container.application_name
        @target_dir       = destination

        FileUtils.rm_rf Dir.glob(PathUtils.join(@target_dir, '*'))
        FileUtils.rm_rf Dir.glob(PathUtils.join(@target_dir, '.[^\.]*'))

        @deployment_ref = ref

        @container.run_in_container_context(ERB.new(GIT_ARCHIVE).result(binding),
            chdir:               @path,
            expected_exitstatus: 0)

        return unless File.exist? PathUtils.join(@target_dir, '.gitmodules')

        env = ::OpenShift::Runtime::Utils::Environ.load(PathUtils.join(@container.container_dir, '.env'))

        cache = PathUtils.join(env['OPENSHIFT_TMP_DIR'], 'git_cache')
        FileUtils.rm_r(cache) if File.exist?(cache)
        FileUtils.mkpath(cache)

        @container.run_in_container_context("/bin/sh #{PathUtils.join('/usr/libexec/openshift/lib', "archive_git_submodules.sh")} #{@path} #{@target_dir}",
            chdir:               @container.container_dir,
            env:                 env,
            expected_exitstatus: 0)

        @container.run_in_container_context("/bin/rm -rf #{cache} &")
      end

      def get_sha1(ref)
        @deployment_ref = ref

        out, _, rc = @container.run_in_container_context(ERB.new(GIT_GET_SHA1).result(binding),
                                                        chdir: @path)

        if 0 == rc
          out.chomp
        else
          # if the repo is empty (no commits) or the ref is invalid, the rc will be nonzero
          ''
        end
      end

      def destroy
        FileUtils.rm_r(@path) if File.exist? @path
      end

      ##
      # Install Git repository hooks and set permissions
      def configure
        @container.set_rw_permission_R(@path)

        # application developer cannot change git hooks
        hooks = PathUtils.join(@path, 'hooks')
        @container.set_ro_permission_R(hooks)

        render_file = lambda { |f, m, t|
          File.open(f, 'w', m) { |f| f.write(ERB.new(t).result(binding)) }
        }

        render_file.call(PathUtils.join(@path, 'description'), 0644, GIT_DESCRIPTION)
        render_file.call(PathUtils.join(@container.container_dir, '.gitconfig'), 0644, GIT_CONFIG)

        render_file.call(PathUtils.join(hooks, 'pre-receive'), 0755, PRE_RECEIVE)
        render_file.call(PathUtils.join(hooks, 'post-receive'), 0755, POST_RECEIVE)
      end

      ##
      # Copy a file tree structure and build an application repository
      def build_bare(path)
        template = PathUtils.join(@container.container_dir, 'git', 'template')
        FileUtils.rm_r(template) if File.exist? template

        git_path = PathUtils.join(@container.container_dir, 'git')
        ::OpenShift::Runtime::Utils::oo_spawn("/bin/cp -ad #{path} #{git_path}",
                       expected_exitstatus: 0)

        ::OpenShift::Runtime::Utils::oo_spawn(ERB.new(GIT_INIT).result(binding),
            chdir:               template,
            expected_exitstatus: 0)
        begin
          # trying to clone as the user proved to be painful as git managed to "lose" the selinux context
          ::OpenShift::Runtime::Utils::oo_spawn(ERB.new(GIT_LOCAL_CLONE).result(binding),
              chdir:               git_path,
              expected_exitstatus: 0)
        rescue ShellExecutionException => e
          FileUtils.rm_r(@path) if File.exist? @path

          raise ShellExecutionException.new(
                    'Failed to clone application git repository from template repository',
                    e.rc, e.stdout, e.stderr)
        ensure
          FileUtils.rm_r(template)
        end
      end

      private
      def ssh_like?(url)
        # HTTP,SSH, and FTP URLs may contain '@' to delimit "user:password" before the host name
        url_s = url.to_s.downcase
        (url_s.include?('@') && ! url_s.include?('//')) || (url_s.start_with? 'ssh:')
      end

      #-- ERB Templates -----------------------------------------------------------

      COUNT_GIT_OBJECTS = 'find objects -type f 2>/dev/null | wc -l'

      GIT_INIT = %q{\
set -xe;
git init;
git config user.email "builder@example.com";
git config user.name "Template builder";
git config core.logAllRefUpdates true;
git add -f .;
git commit -a -m "Creating template";
}

    GIT_INIT_BARE = %q{
set -xe;
git init --bare;
git config core.logAllRefUpdates true;
}

      GIT_LOCAL_CLONE = %q{\
set -xe;
git clone --bare --no-hardlinks template <%= @application_name %>.git;
GIT_DIR=./<%= @application_name %>.git git config core.logAllRefUpdates true;
GIT_DIR=./<%= @application_name %>.git git repack;
}

      GIT_URL_CLONE = %q{\
set -xe;
git clone --bare --no-hardlinks '<%= OpenShift::Runtime::Utils.sanitize_url_argument(@url) %>' <%= @application_name %>.git;
GIT_DIR=./<%= @application_name %>.git git config core.logAllRefUpdates true;
<% if @commit && !@commit.empty? %>
GIT_DIR=./<%= @application_name %>.git git reset --soft '<%= OpenShift::Runtime::Utils.sanitize_argument(@commit) %>';
<% end %>
GIT_DIR=./<%= @application_name %>.git git repack;
}

      GIT_ARCHIVE = %Q{
set -xe;
shopt -s dotglob;
if [ "$(#{COUNT_GIT_OBJECTS})" -eq "0" ]; then
  exit 0;
fi
git archive --format=tar <%= @deployment_ref %> | (cd <%= @target_dir %> && tar --warning=no-timestamp -xf -);
}

      GIT_DESCRIPTION = %q{
<%= @cartridge_name %> application <%= @application_name %>
}

      GIT_CONFIG = %q{
[user]
  name = OpenShift System User
[gc]
  auto = 100
}

      GIT_GET_SHA1 = %Q{
set -xe;
git rev-parse --short <%= @deployment_ref %>
}

      PRE_RECEIVE = %q{
gear prereceive
}

      POST_RECEIVE = %q{
gear postreceive
}
    end
  end
end
