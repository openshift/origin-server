#
# Rake tasks to generate markup documentation
#

#
# Generate markup documentation from Ruby source code
# 
# ENV['docdir'] - target location for the output 
#
require 'yard'
desc "Generate documentation"
YARD::Rake::YardocTask.new() do |t|
  t.options = ['--protected', '--private', '--no-yardopts']
  docdir = ENV['docdir']
  if not docdir == nil
    t.options += ["--output-dir", docdir]
  end
end

#
# Remove the output results from yard document generation
#
require 'fileutils'
desc "remove yardoc artifacts"
task :clean_yard do
  FileUtils.rm_rf 'doc'
  FileUtils.rm_rf '.yardoc'
end

#
# Generate a list of source directories to scan.
# The directories are absolute paths.
# This is used to generate comprehensive documentation in a single
# output location.
#
# Define YARD_SOURCES and YARD_SOURCEROOT in your Rakefile to allow
# generation of comprehensive documentation
#
desc "report doc sources"
task :yard_sources do
  # source list defaults to the 'lib' subdirectory
  sourcelist = (defined? YARD_SOURCES) ? YARD_SOURCES : ['lib']
  here = (defined? YARD_SOURCEROOT) ? YARD_SOURCEROOT + "/" : "."
  puts YARD_SOURCES.map {|d| here + d }.join(' ')
end
