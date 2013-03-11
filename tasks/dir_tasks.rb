#
# Rake tasks for traversing directories containing package trees.
#
# @author Mark Lamourine <markllama@redhat.com>
#

#
# Walk the source tree finding and installing build requirements for
# each package as it is found
#
desc "install build requirements from subdirectories"
task :builddep, :answer do |t, args|
  subdirs = FileList["*/Rakefile"].each do |rf|
    dirname = File.dirname(rf)
    begin
      cmd = "cd #{dirname} ; rake #{t.name}"
      cmd += "[" + args[:answer] + "]" if ['yes', 'no'].include? args[:answer]
      system cmd
    rescue
      puts "failed to #{t.name} in #{dirname}"
    end
  end
end

#
# Walk the source tree finding an generating documentation for each
# package as it is found
#
desc "generate yard documentation in subdirectories"
task :yard, :docdir do |t, args|
  
  subdirs = FileList["*/Rakefile"].each do |rf|
    dirname = File.dirname(rf)
    cmd = "cd #{dirname} ; rake #{t.name}"
    docdir = args[:docdir]
    cmd += "[#{docdir}]" if not docdir == nil
    begin
      system cmd
    rescue
      puts "failed to #{t.name} in #{dirname}"
    end
  end
end

#
# Walk the source tree finding package directories and emitting
# the location of each directory to use as input
# 
desc "report doc sources"
task :yard_sources do |t|
  subdirs = FileList["*/Rakefile"].each do |rf|
    dirname = File.dirname(rf)
    begin
      system "cd #{dirname} ; rake #{t.name} 2>/dev/null"
    rescue
      ""
    end
  end
end

#
# Walk the source tree finding package directories and
# generate RPM for each one
#
# repodir: the destination for build artifacts and RPMs
# test: boolean - if set, generate test RPM
#
desc "generate RPM packages in subdirectories"
task :rpm, :repodir, :test, :yum do |t, args|
  subdirs = FileList["*/Rakefile"].each do |rf|
    dirname = File.dirname(rf)
    cmd = "cd #{dirname} ; rake #{t.name}"
    repodir = args[:repodir] || ""
    testflag = args[:test] || ""
    yum = args[:yum] || ""
    cmd += "[#{repodir},#{testflag},${yum}]"
    begin
      system cmd
    rescue
      puts "failed to #{t.name} in #{dirname}"
    end
  end
end

#
# Walk the source tree finding package directories
# Generate test RPM for each one located
#
# repodir: destination for build artifacts and RPMs
#
desc "generate test RPM packages in subdirectories"
task :testrpm, :repodir, :yum do |t, args|
  subdirs = FileList["*/Rakefile"].each do |rf|
    dirname = File.dirname(rf)
    cmd = "cd #{dirname} ; rake #{t.name}"
    repodir = args[:repodir] || ""
    yum = args[:yum] || ""
    cmd += "[#{repodir},#{yum}]"
    begin
      system cmd
    rescue
      puts "failed to #{t.name} in #{dirname}"
    end
  end
end

