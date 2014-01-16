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

require 'date'
require_relative '../test_helper'
require_relative '../../lib/openshift-origin-node/model/deployment_metadata'

class DeploymentMetadataFuncTest < OpenShift::NodeBareTestCase
  METADATA = '{"git_ref":"master","git_sha1":"4ff2baa","id":"9eca89d5","hot_deploy":null,"force_clean_build":null,"activations":[1389894268.4641075],"checksum":"a4e1963da1984107145dabb1cbbcc8f5251565aa"}'

  def setup
    @home                = '/tmp/DeploymentMetadataTest'
    @deployment_datetime = '2014-01-16_12-44-14.914'
    teardown

    logger = mock()
    logger.stubs(:warn)

    @container = mock()
    @container.stubs(:container_dir).returns(@home)
    @container.stubs(:set_rw_permission)
    @container.stubs(:logger).returns(logger)

    @path = File.join(@home, 'app-deployments', @deployment_datetime, 'metadata.json')
    FileUtils.mkpath File.dirname(@path)
  end

  def teardown
    FileUtils.rm_rf @home
  end

  def test_success
    IO.write(@path, METADATA)
    o = OpenShift::Runtime::DeploymentMetadata.new(@container, @deployment_datetime)
    refute_nil o
    assert_equal '4ff2baa', o.git_sha1
  end

  def test_empty_metadata
    IO.write(@path, '')
    o = OpenShift::Runtime::DeploymentMetadata.new(@container, @deployment_datetime)
    refute_nil o
    assert_equal 'master', o.git_ref
    assert_nil o.git_sha1
  end
end
