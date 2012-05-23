#!/bin/env ruby

require 'facter'
require 'yaml'

puts YAML.dump(Facter.to_hash)