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
require_relative '../test_helper'

module OpenShift
  class BashSdkTest < NodeTestCase
    def setup
      @ld_library_path='/usr/local/lib'
    end

    def test_path_prepend
      actual = %x(source /usr/lib/openshift/cartridge_sdk/bash/sdk
        path_prepend "a:b" #{@ld_library_path} )
      assert_equal "#{@ld_library_path}:a:b", actual
    end

    def test_path_append
      actual = %x(source /usr/lib/openshift/cartridge_sdk/bash/sdk
        path_append "a:b" #{@ld_library_path} )
      assert_equal "a:b:#{@ld_library_path}", actual
    end

    def test_path_prepend_dedup
      actual = %x(source /usr/lib/openshift/cartridge_sdk/bash/sdk
        path_prepend "a:b:#{@ld_library_path}" #{@ld_library_path} )
      assert_equal "#{@ld_library_path}:a:b", actual
    end

    def test_path_append_dedup
      actual = %x(source /usr/lib/openshift/cartridge_sdk/bash/sdk
        path_append "a:b:#{@ld_library_path}" #{@ld_library_path} )
      assert_equal "a:b:#{@ld_library_path}", actual
    end

    def test_path_prepend_path
      actual = %x(source /usr/lib/openshift/cartridge_sdk/bash/sdk
        path_prepend "a:b" #{@ld_library_path}:#{@ld_library_path} )
      assert_equal "#{@ld_library_path}:#{@ld_library_path}:a:b", actual
    end

    def test_path_append_path
      actual = %x(source /usr/lib/openshift/cartridge_sdk/bash/sdk
        path_append "a:b" #{@ld_library_path}:#{@ld_library_path} )
      assert_equal "a:b:#{@ld_library_path}:#{@ld_library_path}", actual
    end

    def test_path_prepend_path_dedup
      actual = %x(source /usr/lib/openshift/cartridge_sdk/bash/sdk
        path_prepend "a:b:#{@ld_library_path}" #{@ld_library_path}:#{@ld_library_path} )
      assert_equal "#{@ld_library_path}:#{@ld_library_path}:a:b", actual
    end

    def test_path_append_path_dedup
      actual = %x(source /usr/lib/openshift/cartridge_sdk/bash/sdk
        path_append "a:b:#{@ld_library_path}" #{@ld_library_path}:#{@ld_library_path} )
      assert_equal "a:b:#{@ld_library_path}:#{@ld_library_path}", actual
    end
  end
end
