require 'rake'
require 'yard'

# use recursive tasks
#require "./tasks/dir_tasks"

namespace :all do
  # ============================================================================
  # Custom top-level tasks for efficiency
  #
  # While these tasks can be done recursively, they're much faster this way.
  # ============================================================================

  #
  # Generate and combine Yard documentation from all sources
  #
  desc "generate comprehensive documentation"
  task :yard, :destdir do | t, args |

    puts "collecting source locations"

    # include manually created markdown documentation
    readme_files = FileList["*.md", "documentation/*.md"]

    # find the source locations indicated in each package
    srclist = `rake yard_sources`.split("\n")
    puts "sourcelist = #{srclist}"

    # Generate docs with standard parameters
    cmd = 'yard doc '
    yardargs = ['--protected', '--private', '--no-yardopts']
    cmd += yardargs.join(' ') + ' '

    # Set the destination for docs if provided
    if not args[:destdir] == nil then
      cmd += "--output-dir #{args[:destdir]} " 
    end

    # compose the doc generation command
    cmd += srclist.join(' ')
    cmd += " - " + readme_files.join(' ')

    # Generate documentation
    system cmd
  end

  #
  # Install all RPM build requirements
  #
  require 'find'
  desc "install all build requirements"
  task :builddep, :answer do |t, args|
    cmd = "yum-builddep "

    answer = args[:answer] || ""
    cmd += " --assume#{answer} " if ['yes', 'no'].include? answer

    speclist = []
    Find.find(".") do | f |
      speclist << f if /\.spec$/.match f
    end
    specfiles = speclist.join(' ')

    cmd += specfiles
    cmd = "sudo " + cmd if not Process.uid == 0
    system cmd
  end

  #
  # Build all RPMs and generate a yum repository
  #
  desc "generate all RPMs and create yum repository"
  task :rpm, :repodir, :test, :yum do |t, args|

    repodir = args[:repodir] || ""
    testflag = args[:test] || "/tmp/tito"

    Find.find(".") do |f|
      if /.spec$/.match f then
        pkgdir = File.dirname f
        system "cd #{pkgdir} ; rake rpm[#{repodir},#{testflag}]"
      end
    end

    # generate the repo metadata    
    system "createrepo #{repodir}" if args[:yum] and File.directory? repodir
  end

  #
  # Create test RPMs from source tree and spec files
  #
  # repodir: destination for artifacts and packages
  #
  desc "generate all test RPMs and create yum repository"
  task :testrpm, :repodir, :yum do |t, args|
    repodir = args[:repodir] || ""
    yum = args[:yum] || ""
    Rake.application.invoke_task("all:rpm[#{repodir},true,#{yum}]")
  end

end
