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


#
# Bug 965317
#
# Under high load, there's achance that writes have their buffers
# duplicated inside the C code for IO.  This problem goes away if you
# set sync=true on the IO object but does not go away if you open with
# File::SYNC or call sync after the write.
#
# Require this file in any program which is likely to be called under
# a heavy load or have a number of threads doing file writes.
#
File.class_eval do
  class << self
    alias_method :open_needs_sync, :open
    alias_method :new_needs_sync,  :new

    def open(*args)
      if block_given?
        open_needs_sync(*args) do |f|
          f.sync=true
          yield(f)
        end
      else
        f=open_needs_sync(*args)
        f.sync=true
        f
      end
    end

    def new(*args)
      f=new_needs_sync(*args)
      f.sync=true
      f
    end

  end
end
