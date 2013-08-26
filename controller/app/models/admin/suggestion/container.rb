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
# Suggestion container (array) with some helper methods
#
module Admin
  module Suggestion
    class Container < ::Array
      def +(add)  # need to return a Container - default morphs to Array
        if add.is_a? Array
          add.each {|x| self << x}
        else # adding an element, don't make me think about += vs <<
          self << add
        end
        self
      end
      def compact  # need to return a Container - default morphs to Array
        Container.new + super
      end

      VALID_SCOPES = %w[general profile district]
      def for_scope(scope, filter = nil)
        VALID_SCOPES.include?(scope) || raise("invalid scope: #{scope}")
        c = Container.new + select {|sugg| sugg.scope == scope}
        return c if filter.nil?
        case scope
          when "profile";  c.for_profile(filter)
          when "district"; c.for_district(filter)
          else;            c
        end
      end
      def for_general
        for_scope("general")
      end
      def for_profile(profile)
        Container.new + select {|sugg| sugg.profile == profile}
      end
      def for_district(uuid)
        Container.new + select {|sugg| sugg.district_uuid == uuid}
      end
      def group_by_profile
        inject(Hash.new) {|h,sugg| (h[sugg.profile] ||= Container.new) << sugg; h }
      end
      def group_by_district_uuid
        inject(Hash.new) {|h,sugg| (h[sugg.district_uuid] ||= Container.new) << sugg; h }
      end
      def group_by_class
        inject(Hash.new) {|h,sugg| (h[sugg.class] ||= Container.new) << sugg; h }
      end
      def important(filter = true)
        Container.new + select {|sugg| sugg.important? == filter}
      end

    end
  end
end
