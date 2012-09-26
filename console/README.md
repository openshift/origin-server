# OpenShift Origin Management Console

RubyGem: openshift-origin-console

The OpenShift Origin management console allow you to manage your OpenShift
applications from the comfort of your browser or mobile phone. The
console can run against OpenShift Origin or the hosted OpenShift server
using the public REST API.

For more details about the console visit the [OpenShift Origin open source
community page](https://openshift.redhat.com/community/open-source).

Please stop by #openshift on irc.freenode.net if you have any questions or
comments.  For more information about OpenShift, visit https://openshift.redhat.com
or the OpenShift forum
https://openshift.redhat.com/community/forums/openshift


## Running the Console locally

DEPENDENCIES: 

* ruby 1.9.3 or later
* rubygems and bundler

Step 1: Extract the source 

Step 2: Download the correct gems with Bundler

    $ bundle install

You should see a success message indicating all of your gems have been
installed:

    $ bundle install
    ....
    Using uglifier (1.2.7) 
    Using webmock (1.6.4) 
    Your bundle is complete! Use `bundle show [gemname]` to see where a bundled gem is installed.

Step 3: Point to your OpenShift Origin server for testing

The console needs an OpenShift server to run against - install using
[our
LiveCD](https://openshift.redhat.com/community/wiki/getting-started-with-openshift-origin-livecd)
or [in a VM with
liveinst](https://openshift.redhat.com/community/wiki/build-your-own-paas-from-the-openshift-origin-livecd-using-liveinst).
Using a text editor create a file ~/.openshift/api.yml and give it the
following contents:

    url: https://<origin_server>/broker/rest

Now set the environment variable CONSOLE_API_MODE=external so the
console knows it should point to that external server.

    $ export CONSOLE_API_MODE=external

Step 4: Run the tests

    $ bundle exec rake test

will execute our entire console test suite against your OpenShift Origin server.

Step 5: To actually launch the console, we'll run the included Rails application
for OpenShift Origin.

    $ cd test/rails_app
    $ bundle exec rails s

You'll see the server start on port 3000 - hit http://localhost:3000 and
provide credentials to log into your Origin server.  Welcome to the
management console!

### Run it on production!

You can also run your console against our OpenShift hosted service using
your own account.  To run:

    $ cd test/rails_app
    $ CONSOLE_API_MODE=openshift bundle exec rails s

You will need to provide your own credentials to access the console.

### Host it on OpenShift

Take it one step further and run OpenShift on OpenShift (note: we accept
no responsibility for universe ending catastrophe).

1.  Create an application on OpenShift based on Ruby 1.9

        $ rhc app create -a console -t ruby-1.9

2.  Copy the contents of the OpenShift Origin console/ directory into your new application

        $ cp -R crankcase/console/* console/
        $ cd console
        $ git add .
        $ git commit -m "Initial source from Origin"
        $ git push

    Note: this loses version history - there should be some Git-fu that
makes this less painful.

3.  Visit the console on OpenShift and log in - you should see your
    applications presented.

## Developing / Contributing

We expect code contributions to follow these standards:

1. Ensure code matches the [GitHub Ruby styleguide](https://github.com/styleguide/ruby), except where the file establishes a different standard.
2. We use Test::Unit with Rails extensions for all our test cases.
3. We try to maintain 100% line coverage of all newly added model and
   controller code via testing.  Coverage reports are generated if
   you have the simplecov gem installed after tests execute via 
   bundle exec rake test.

Once you've made your changes:

1. [Fork](http://help.github.com/forking/) the code
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create a [Pull Request](http://help.github.com/pull-requests/) from your branch
5. That's it!

