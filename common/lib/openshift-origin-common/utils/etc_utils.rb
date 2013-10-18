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

require 'etc'

module EtcUtils
  def getpwnam(user)
    return nil unless user

    (user.to_i > 4294967295) ?
        Etc.getpwnam(user.to_s) :
        Etc.getpwnam(user)
  end

  module_function :getpwnam


  def getgrnam(group)
    return nil unless group

    (group.to_i > 4294967295) ?
        Etc.getgrnam(group.to_s) :
        Etc.getgrnam(group)
  end

  module_function :getgrnam

end
