# Building OpenShift Origin Packages

The OpenShift Origin build tree uses Rake to automate the package and
documentation build process.  A small set of task files are stored in
the _tasks_ directory at the root of the source tree.  These can be
included in the Rakefile in each sub-directory and in the root
directory for each package.

# <a id="Prerequisites">Prerequisites</a>

Before you can start building the software you need to have a build
host (a computer set up to run the builds) and the software which is
used to orchestrate the process.

The [OpenShift](http://openshift.redhat.com) project
[source code](https://github.com/openshift/origin-server) is hosted on
[Github](https://github.com) and the source code is managed with
[git](http://git-scm.com/). The software is packaged in RPM format
(with some as [Rubygems](http://rubygems.org) as an intermediate
format). The package building program is _rpmbuild_. The packaging is
managed by [Tito](https://github.com/dwoodson/tito). Repository
management is done by _yum_ (using yum-utils). The build tasks
are defined by [Rake](http://rubygems.org/gems/rake). The
documentation is compiled with [Yard](http://yardoc.org) (another
rubygem). Testing is done with
[Rspec 2.x](https://www.relishapp.com/rspec) and
[Cucumber](http://cukes.info/).

All of these must be installed on the build system before the
OpenShift Origin software can be built.

    yum install git rubygem-rake rubygem-yard rubygem-redcarpet \
        rpm-build tito yum-utils rubygem-bundler \
        rubygem-rspec-core rubygem-rspec-mocks \
        rubygem-rspec-expectations rubygem-rspec-rails \
        rubygem-cucumber

# <a id="Standard Tasks">Standard Tasks</a>

You can check at any level what tasks are available using the _rake_
command.  This is a sample of the tasks at the top of the source
tree. Not all of these will be available in any other location.

    $ rake --tasks
    rake all:builddep[answer]      # install all build requirements
    rake all:yard[docdir]          # generate comprehensive documentation
    rake all:rpm[repodir,test,yum] # generate all RPMs and create yum repo
    rake all:testrpm[repodir,yum]  # generate all RPMs and create yum repo
    rake builddep[answer]          # install build requirements from subdirs
    rake rpm[repodir,test,yum]     # generate RPM packages in subdirectories
    rake testrpm[repodir,yum]      # generate test RPM packages in subdirs
    rake yard[docdir]              # generate yard docs in subdirectories
    rake yard_sources              # report doc sources
    
There are three files in ```tasks/``` in the top of the source
tree. These define a set of standard tasks.

te markup docs
* **build_tasks.rb** - tasks for building or preparing to build packages
 * _builddep_ - install packages needed to build this package
 * _rpm[repodir,test,yum]_ - build the release version of this package
 * _testrpm[repodir,yum]_ - build the test version of this package


* **yard_tasks.rb** - tasks for generating markup documentation 
 * _yard_ - generate markup documentation
 * *yard_sources* - list the source subdirectories and files for markup


* **dir_tasks.rb** - tasks for a directory containing other packages.
 * _rpm[repodir,test,yum]_ - pass down the rpm task to children
 * _testrpm[repodir,yum]_ - pass down the testrpm task to children
 * _yard_ - pass down the yard task to children
 * *yard_sources* - list the source subdirectories for all children

You can ```require``` one or more of these in a Rakefile to enable the
standard tasks.

## Install Package Build Requirements

When the [prerequisites](#Prerequisites) have been installed you can
start using the build tasks.  The first task is to insure that all of
the build requirements for the packages are in place.

Each package directory should have a Rake task named _builddep_.  You
can run that task in the package directory.  You can also run it from
the root of the source tree. It will walk the source tree examining
each package and installing the build requirements.

The first time you're installing you can run a special target
*all:builddep* at the root of the source tree.  This target is more
efficient at installing all of the requirements at once.

    rake all:builddep # install all build requirements
    rake builddep     # install the build requirements for one package
    
The _yum-builddep_ program that is used must be run as root.  If you
are not the root user when you run this target it will use _sudo_.
You will need to have sudo enabled and enter your password once.
    
## Generate Software Packages and Repository

Once all of the build requirements for all of the software have been
installed you can proceed to creating the software packages. There are
two tasks to generate packages.

* _rpm_ - generate release (tagged) packages
* _testrpm_ - generate test package from the most recent commit

Both tasks can take arguments (presented in square brackets suffixed
to the task name).

* _repodir_ - the destination for packaging artifacts and a _yum_
  repository.

* _test_ - rpm only - create test RPMs instead of release packages.

* _yum_ -  both - run createrepo in the destination after building.

  __NOTE__: Rake doesn't read ```.titorc``` so you must specify the
  location of the RPM destination to properly generate the yum metadata.

### Release (tagged) Packages

Each package will have a target named _rpm_ which will invoke _tito_
to execute the build and place the RPM in to a repository. The _rpm_
task will generate the most recent tagged release of the package.

    rake all:rpm[/var/www/httpd/yum] # build all RPMs and create repo
    rake rpm # build one (or all) packages in the default destination
    rake rpm[/var/cache/yumrepo] # build packages in alternate destination
    
    

### Test Packages

You can use the _rpm_ task to build test RPMs but a shortcut has been
provided. The _testrpm_ task is used in the same way as the _rpm_ task
but will generate test RPMs with versions which allow them to be
installed and updated with ```yum update``` as development proceeds.

    rake testrpm # build one or all packages to the default location
    rake testrpm[/home/devuser/yumrepo] # build to alternate location

## Generate Code Markup Documentation

It has become fairly common practice to automatically generate
function and class documentation using some form of markup in comments
in-line with source code.  Ruby has a number of tools that will do
this. The OpenShift project is using the [Yard](http://yardoc.org)
documentation generator.  All of the ruby code should be marked up to
provide useful documentation.

A set of tasks have been provided to trigger the generation of markup
documentation. Each package should have a _yard_ target to generate a
local copy of the documentation for that package alone.  This can be
integrated with the package build process so that the documentation
can be included in the package.

At the top of the software tree a custom _yard_ target will build a
comprehensive documentation set for all of the packages included in
the tree.  By default the _yard_ target places the resulting output in
the a subdirectory of the current working directory. The output
location is named named ```./doc``` .

Like the _rpm_ and _testrpm_ targets, the top level _yard_
target can take an argument to place the output in a custom location.

    rake all:yard[/var/www/html/osdocs] # place docs where apached can see
    rake yard # generate documentation and place it in the default location.
   
_NOTE_ : due to a peculiarity in the default _yard_ rake target, the
alternate location argument is only available for the comprehensive
build target at the root of the source tree. 

# Adding Software

When you add a new package to the source tree you should add a
Rakefile to your package root directory and to any parent directory
which doesn't already have one.  You can use one of the existing ones
as a sample.  If you include any of the
[Standard Tasks](#Standard Tasks) you will need to adjust the _require_
line to refer to the right number of parent directories.

## Including the [Standard Tasks](#Standard Tasks)

* Create a Rakefile
* add _require_ lines
* adjust for the depth
* add custom tasks as needed

### Directory Rakefiles

Rake tasks can walk the entire source repository, executing the task
in each package root.  To do this each directory must have a set of
tasks which will look down into their children and pass the task down.
The directories which contain children must have a set of tasks to do that.

Example:

    cat plugins/Rakefile 
    #
    # A Rakefile for a parent directory with no custom tasks
    #
    require "../tasks/dir_tasks"

This file sits one level below the root of the source tree.  It is a
directory which contains nothing but subdirectories.  The
subdirectories may contain packages or other children which contain
their own Rakefile.

### Package Rakefiles

The Rakefile in the root directory of a package will need to include
at least the *build_tasks.rb* file.  If the package contains Ruby code
with markup commentary it should also include the *yard_tasks.rb* file
as well.  Remember to adjust the path to reach the ```tasks```
directory at the root of the source tree.

Example:

    cat plugins/dns/bind/Rakefile
    # 
    # Standard Tasks
    #
    require "../../../tasks/build_tasks"
    require "../../../tasks/yard_tasks" 
    
    # Define these to allow generation of comprehensive yard docs
    YARD_SOURCEROOT = File.dirname(__FILE__)
    YARD_SOURCES = ['lib']
    
    # Custom test task
    require 'rake/testtask'
    
    Rake::TestTask.new(:test) do |t|
      t.libs << 'test'
      t.test_files = FileList['test/**/*_test.rb']
      t.verbose = true
    end

Note first that the ```require``` lines for the OpenShift standard
tasks have been adjusted for the depth of the Rakefile in the source
tree.

Second, note the *YARD_SOURCEROOT* and *YARD_SOURCES* constants.
These are used by the *yard_sources* target.  They tell the *all:yard*
target at the root what source files and directories to include in the
comprehensive documentation output.

Finally this file defines a custom _test_ task using the Rake testtask module.

## Adding Custom Tasks

If you need custom tasks for a given package, feel free to add them to
the local Rakefile.  Be aware of the standard tasks so you can avoid
accidentally overriding them.

See the example above.

## Adding "Standard" Tasks

Because the [Standard Tasks](#Standard Tasks) are defined in one place
in the source tree, it is possible to add new "standard" tasks without
editing all of the Rakefiles in the tree.

You need to be sure that the new task will not conflict with any
existing tasks.  If you want the top level Rakefile task to walk the
entire source tree, you will need to add a matching task to the
*dir_tasks.rb* file.

If you want to create a new *class* of standard tasks (tasks that do
not fall into "build", "yard" or "dir", you __will__ have to create a
new task definition file at the top level and add that to each of the
appropriate Rakefiles in the source tree.  The only obvious class I
can think of is __test__. This should not happen often after this
system has been in use for a while.

# References

* __Git__: The [Git](http://git-scm.com/) software revision control system
* __Github__: (https://github.com) - The hosting site for OpenShift Origin
* __Rake__: [Ruby Make](http://rake.rubyforge.org/) - development tasks
* __Yard__: [Generate API documentation from code markup](http://yardoc.org/)
* __Tito__: [Generate RPM packages and repository](http://github.com/dgoodwin/tito)
* __Rspec__: [Unit testing framework for test driven development](https://www.relishapp.com/rspec)
* __Cucumber__: [Behavior driven functional and integration testing framework](http://cukes.info)
