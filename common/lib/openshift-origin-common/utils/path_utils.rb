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

require 'fileutils'
require 'etc'
require 'pathname'

module PathUtils
  def self.private_module_function(name)   #:nodoc:
    module_function name
    private_class_method name
  end

  ##
  # Method oo_chown wrapper for FileUtils.chown.
  #
  # Created because an error in FileUtils.chown where an all digit user or group name is assumed
  # to be a uid or a gid. Mongoids can be all numeric.
  def oo_chown(user, group, list, options = {})
    user  = pu_get_uid(user)
    group = pu_get_gid(group)

    FileUtils.chown(user, group, list, options)
  end

  module_function :oo_chown

  ##
  # Method oo_chown_R wrapper for FileUtils.chown_R.
  #
  # Created because an error in FileUtils.chown where an all digit user or group name is assumed
  # to be a uid or a gid. Mongoids can be all numeric.
  def oo_chown_R(user, group, list, options = {})
    user  = pu_get_uid(user)
    group = pu_get_gid(group)

    FileUtils.chown_R(user, group, list, options)
  end

  module_function :oo_chown_R

  ##
  # Created to mimic oo_chown, but symbolic links are *NOT* dereferenced.
  def oo_lchown(user, group, *list)
    user  = pu_get_uid(user)
    group = pu_get_gid(group)

    File.lchown(user, group, *list)
  end

  module_function :oo_lchown

  # PathUtils.join(string, ...)  ->  path
  #
  # Returns a new string formed by joining the strings using
  # <code>File::SEPARATOR</code>.
  #
  # Differs from +File.join+ in as much as Pathname is used to sanitize and canonize the path.
  #
  #    PathUtils.join("usr", "mail", "gumby")   #=> "usr/mail/gumby"
  def join(string, *smth)
    Pathname.new(File.join(string, smth)).cleanpath.to_path
  end

  module_function :join

  def pu_get_uid(user)
    return nil unless user
    case user
      when Integer
        user < 4294967296 ? user : Etc.getpwnam(user.to_s).uid
      when /\A\d{1,10}\z/
        user.to_i
      else
        Etc.getpwnam(user).uid
    end
  end

  private_module_function :pu_get_uid

  def pu_get_gid(group)
    return nil unless group

    case group
      when Integer
        group < 4294967296 ? group : Etc.getgrnam(group.to_s).gid
      when /\A\d{1,10}\z/
        group.to_i
      else
        Etc.getgrnam(group).gid
    end
  end

  private_module_function :pu_get_gid
end
