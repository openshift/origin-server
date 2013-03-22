#
# Tasks to build packages from source trees
#

#
# Install build requirements.
# Use sudo(1) if caller is not root
#
# answer: "yes" or "no" - assume yes or no to yum questions
#
desc "Install build dependencies for this package"
task :builddep, :answer do |t, args|
  specfiles = Dir.glob("*.spec")
  if specfiles.length != 1 then
    raise Exception.new("there must be exactly one specfile") 
  end
  builddep_cmd = "yum-builddep #{specfiles[0]}"
  if not args[:answer] == nil then
    if not ['yes', 'no'].include? args[:answer]
      raise Exception.new("builddep answer must be 'yes' or 'no'")
    end
    builddep_cmd += " --assume#{args[:answer]}"
  end
  builddep_cmd = "sudo " + builddep_cmd if not Process.uid == 0
  system builddep_cmd
end

#
# Build an RPM from the source tree and spec file using tito
#
# repodir: the destination for artifacts and packages
# test: boolean - build test packages if set
#
desc "Create installable RPM package"
task :rpm, :repodir, :test, :yum do |t, args|
  build_cmd = "tito build --rpm"

  repodir = args[:repodir] || ""
  if not repodir == "" then
    sh "mkdir -p #{repodir}" if not Dir.exists? repodir
    build_cmd += " --output #{repodir}"
  end

  if args[:test] then
    build_cmd += " --test"
  end
  system build_cmd

  system "createrepo #{repodir}" if args[:yum] and File.directory? repodir
end

#
# Create test RPMs from source tree and spec files
#
# repodir: destination for artifacts and packages
#
desc "Create installable RPM package for testing"
task :testrpm, :repodir, :yum do |t, args|
  repodir = args[:repodir] || ""
  yum = args[:yum] || ""
  Rake.application.invoke_task("rpm[#{repodir},true,#{yum}]")
end
