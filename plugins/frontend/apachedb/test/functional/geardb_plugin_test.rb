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

require 'active_support/core_ext/class/attribute'

require 'openshift-origin-frontend-apachedb'
require 'test_helper'

module OpenShift

  class GearDBPluginTestCase < FrontendHttpPluginTestCase

    def setup
      @geardb = Hash.new
      ::OpenShift::Runtime::Frontend::Http::Plugins::GearDB.stubs(:open).yields(@geardb)

      @plugin_class = ::OpenShift::Runtime::Frontend::Http::Plugins::GearDBPlugin
      @plugin = @plugin_class.new(@container_uuid, @fqdn, @container_name, @namespace)

      exercise_plugin_is_available

      @plugin.create

      @geardb_entry = {
        'fqdn' => @fqdn,
        'container_name' => @container_name,
        'namespace' => @namespace
      }

      assert_equal @geardb_entry, @geardb[@container_uuid], "GearDB entry is incorrect"
    end

    def test_lookup_by_uuid
      assert_equal nil, @plugin.class.lookup_by_uuid(@fqdn), "UUID lookup with FQDN should have failed."

      ent = @plugin.class.lookup_by_uuid(@container_uuid)
      assert ent, "Lookup by UUID should have returned an object"
      assert_equal @container_uuid, ent.container_uuid, "Lookup by UUID returned object wrong container_uuid"
      assert_equal @fqdn, ent.fqdn, "Lookup by UUID returned object wrong fqdn"
      assert_equal @container_name, ent.container_name, "Lookup by UUID returned object wrong container_name"
      assert_equal @namespace, ent.namespace, "Lookup by UUID returned object wrong namespace"
    end

    def test_lookup_by_fqdn
      assert_equal nil, @plugin.class.lookup_by_fqdn(@container_uuid), "FQDN lookup with UUID should have failed."

      ent = @plugin.class.lookup_by_fqdn(@fqdn)
      assert ent, "Lookup by FQDN should have returned an object"
      assert_equal @container_uuid, ent.container_uuid, "Lookup by FQDN returned object wrong container_uuid"
      assert_equal @fqdn, ent.fqdn, "Lookup by FQDN returned object wrong fqdn"
      assert_equal @container_name, ent.container_name, "Lookup by FQDN returned object wrong container_name"
      assert_equal @namespace, ent.namespace, "Lookup by FQDN returned object wrong namespace"
    end

    def test_all
      plset = @plugin.class.all.to_a

      assert_equal 1, plset.length, "There should be one entry in the set."
      ent = plset[0]
      assert_equal @container_uuid, ent.container_uuid, "All returned object wrong container_uuid"
      assert_equal @fqdn, ent.fqdn, "All returned object wrong fqdn"
      assert_equal @container_name, ent.container_name, "All returned object wrong container_name"
      assert_equal @namespace, ent.namespace, "All returned object wrong namespace"
    end

    def teardown
      @plugin.destroy

      assert @geardb.empty?, "GearDB should be empty"
    end

  end

end
