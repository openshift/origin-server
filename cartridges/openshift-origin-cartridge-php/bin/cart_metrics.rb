#!/usr/bin/env oo-ruby

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

def main
  apache_metrics
end


def apache_metrics
  puts `curl -s http://$OPENSHIFT_PHP_IP:8080/server-status?auto`
end

def process_cart_metrics metrics_string
  metrics = metrics_string.split("\n")
  metrics.map! do |metric|
    key, value = metric.split(": ")
    key = key.split(/(?=[A-Z])/).map!{|word| word.downcase}
  end
end


main