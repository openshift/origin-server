# OpenShift Ruby Cartridge

The `ruby` cartridge provides a bare metal [Rack](http://rack.github.io) application with [Ruby](http://www.ruby-lang.org).

## Template Repository Layout

    tmp/               Temporary storage
    public/            Content (images, css, etc. available to the public)
    config.ru          This file is used by Rack-based servers to start the application.
    .openshift/        Location for OpenShift specific files
      action_hooks/    See the Action Hooks documentation [1]
      markers/         See the Markers section [2]

\[1\] [Action Hooks documentation](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md#action-hooks)
\[2\] [Markers](#markers)


### Notes about layout

Every time you push, everything in your remote repo dir gets recreated, please
store long term items (like an sqlite database) in the OpenShift data
directory, which will persist between pushes of your repo.
The OpenShift data directory is accessible relative to the remote repo
directory (../data) or via an environment variable `OPENSHIFT_DATA_DIR`.

## Ruby Mirror

OpenShift is mirroring rubygems.org at http://mirror1.ops.rhcloud.com/mirror/ruby/
This mirror is on the same network as your application, and your gem download should be faster.

To use the OpenShift mirror:

Edit your Gemfile and replace
    source 'http://rubygems.org'

with
    source 'http://mirror1.ops.rhcloud.com/mirror/ruby/'

Edit your Gemfile.lock and replace
    remote: http://rubygems.org/

with
    remote: http://mirror1.ops.rhcloud.com/mirror/ruby/


## Rails 3.0

Option 1) (Recommended) Git push your application `Gemfile/Gemfile.lock`.  This will 
cause the remote OpenShift node to run `bundle install --deployment` to download and 
install your dependencies.  Each subsequent git push will use the previously
downloaded dependencies as a starting point, so additional downloads will be a delta.

Option 2) Git add your `.bundle` and `vendor/bundle` directories after running
`bundle install --deployment` locally.  Be sure to exclude any gems that have native 
code or ensure they can run on RHEL x86_64.


## Environment Variables

The `ruby` cartridge provides several environment variables to reference for ease
of use:

    OPENSHIFT_RUBY_LOGDIR          Log files go here.
    OPENSHIFT_RUBY_VERSION         The Ruby language version. The valid values are `1.8` and `1.9`.

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).
