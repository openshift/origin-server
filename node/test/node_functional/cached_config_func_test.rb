#--
# Copyright 2014 Red Hat, Inc.
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

require 'date'
load Pathname.new(__FILE__).dirname + '../../../node-util/sbin/oo-watchman'

class CachedConfigFuncTest < OpenShift::NodeBareTestCase
  def setup
    @path = '/tmp/CachedConfigFuncTest'
    @conf = File.join(@path, 'node.conf')

    teardown

    FileUtils.mkpath @path
    @default_value = 'default value'
  end

  def teardown
    FileUtils.rm_rf @path
  end

  def test_no_config
    assert_raises(Errno::ENOENT) do
      OpenShift::Runtime::CachedConfig.new('/please/never/create/this/file')
    end
  end

  def test_element
    elements = %Q{GEAR_BASE_DIR="/var/lib/openshift"                           # gear root directory
GEAR_GECOS='OpenShift guest'                                 # Gecos information to populate for the gear user
UNIT_TEST=
}
    IO.write(@conf, elements)
    config       = OpenShift::Runtime::CachedConfig.new(@conf)
    last_updated = config.last_updated

    assert_equal 3, config.keys.count
    assert_equal last_updated, config.last_updated
    assert_equal '/var/lib/openshift', config.get('GEAR_BASE_DIR', @default_value)
    assert_equal last_updated, config.last_updated
    assert_equal 'OpenShift guest', config.get('GEAR_GECOS', @default_value)
    assert_equal '', config.get('UNIT_TEST', @default_value)
    assert_equal @default_value, config.get('', @default_value)
    assert_equal last_updated, config.last_updated
  end

  def test_update
    elements = %Q{GEAR_BASE_DIR="/var/lib/openshift"                           # gear root directory\n}
    IO.write(@conf, elements)

    config       = OpenShift::Runtime::CachedConfig.new(@conf)
    last_updated = config.last_updated

    assert_equal 1, config.keys.count

    elements += %Q{GEAR_GECOS='OpenShift guest'                                 # Gecos information to populate for the gear user\n}
    IO.write(@conf, elements)

    # set mtime back a second to ensure test always works.  In real world, the next access would pick up change
    rewind = Time.now - 60
    File.utime(rewind, rewind, @conf)

    assert_equal 'OpenShift guest', config.get('GEAR_GECOS', @default_value)
    assert_equal 2, config.keys.count
    refute_equal last_updated, config.last_updated
  end
end