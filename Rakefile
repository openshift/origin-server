require 'rake'

begin
  require 'yard'

  namespace :doc do
    desc 'Create Ruby docs for all components'
    task :gen do
      doc_dir = File.join(File.dirname(__FILE__), "doc")
      FileUtils.rm_rf(doc_dir)
      gems = Dir.glob("**/*.gemspec")
      gems.each do |gem_file|
        gem_src_dir = File.dirname(gem_file)
        FileUtils.mkdir_p File.join(doc_dir, gem_src_dir)
        
        args = ['--protected', '--private', '--no-yardopts', "--output-dir #{File.join(doc_dir, gem_src_dir)}"] #, File.join(gem_src_dir, "**/*")
        system "cd #{gem_src_dir}; yardoc #{args.join(" ")}\n"
        system "yardoc README.md"
      end
    end
  end
rescue LoadError => e
  print e.message
  # YARD is not available
end
