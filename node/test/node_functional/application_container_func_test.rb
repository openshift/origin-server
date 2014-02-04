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
require 'securerandom'
require 'digest/sha1'

class ApplicationContainerFuncTest < OpenShift::NodeTestCase
  GEAR_BASE_DIR = '/var/lib/openshift'

  def setup
    @uid  = 5993
    @uuid = SecureRandom.uuid.gsub(/-/, '')

    @config.stubs(:get).with("GEAR_BASE_DIR").returns(GEAR_BASE_DIR)
    @config.stubs(:get).with("GEAR_GECOS").returns('Functional Test')
    @config.stubs(:get).with("CREATE_APP_SYMLINKS").returns('0')
    @config.stubs(:get).with("GEAR_SKEL_DIR").returns(nil)
    @config.stubs(:get).with("GEAR_SHELL").returns(nil)
    @config.stubs(:get).with("CLOUD_DOMAIN").returns('example.com')
    @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns('/etc/httpd/conf.d/openshift')
    @config.stubs(:get).with("PORT_BEGIN").returns(nil)
    @config.stubs(:get).with("PORT_END").returns(nil)
    @config.stubs(:get).with("PORTS_PER_USER").returns(5)
    @config.stubs(:get).with("UID_BEGIN").returns(@uid)
    @config.stubs(:get).with("BROKER_HOST").returns('localhost')
    @config.stubs(:get).with('REPORT_BUILD_ANALYTICS').returns(false)

    begin
      %x(userdel -f #{Etc.getpwuid(@uid).name})
    rescue ArgumentError
    end

    @container = OpenShift::Runtime::ApplicationContainer.new(@uuid, @uuid, @uid,
                                                              'ApplicationContainerFuncTest',
                                                              'ApplicationContainerFuncTest',
                                                              'functional-test')
  end

  def teardown
    @container.destroy
  end

  def test_secret_token
    path  = File.join(@container.container_dir, '.env', 'OPENSHIFT_SECRET_TOKEN')
    token = Digest::SHA1.base64digest(SecureRandom.random_bytes(256))

    @container.create(token)

    assert_path_exist(path)
    assert_equal(token, IO.read(path), 'Secret Token corrupt')
  end

  def test_override_secret
    @container.create(Digest::SHA1.base64digest(SecureRandom.random_bytes(256)))

    path  = File.join(@container.container_dir, '.env', 'user_vars', 'OPENSHIFT_SECRET_TOKEN')
    token = Digest::SHA1.base64digest(SecureRandom.random_bytes(256))
    @container.user_var_add('OPENSHIFT_SECRET_TOKEN' => token)


    assert_path_exist(path)
    assert_equal(token, IO.read(path), 'Secret Token corrupt')

    env = OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
    assert_equal(token, env['OPENSHIFT_SECRET_TOKEN'])
  end
end
