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

require 'logger'

module OpenShift
  module NodeLogger

    def logger
      NodeLogger.logger
    end

    def self.logger
      @logger ||= begin
        path = File.join(File::SEPARATOR, %w{var log openshift node})
        FileUtils.mkpath(path)

        log_file = File.join(path, 'platform.log')
        file     = if File.exist?(log_file)
                     File.open(log_file, File::WRONLY | File::APPEND)
                   else
                     File.open(log_file, File::WRONLY | File::APPEND| File::CREAT, 0644)
                   end
        Logger.new(file, 5, 10 * 1024 * 1024)
      rescue Exception => e
        Logger.new(STDERR).error { "Failed with #{e.message}" }
        Logger.new(STDOUT)
      end
    end
  end
end