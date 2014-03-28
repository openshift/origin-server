#--
# Copyright 2010 Red Hat, Inc.
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

module OpenShift
  VERSION = File.open("#{File.dirname(__FILE__)}/../../rubygem-openshift-origin-node.spec"
                        ).readlines.delete_if{ |x| !x.to_s.encode('UTF-8', invalid: :replace).match(/Version:/)
                        }.first.split(':')[1].strip
  SDK_PATH = File.dirname(__FILE__)
end
