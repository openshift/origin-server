# OpenShift Jenkins Cartridge

The `jenkins` cartridge provides the Jenkins continuous integration server on OpenShift.

## Template Repository Layout

    .openshift/        Location for OpenShift specific files
      action_hooks/    See the Action Hooks documentation [1]
      markers/         See the Markers section [2]

\[1\] [Action Hooks documentation](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md#action-hooks)
\[2\] [Markers](#markers)


## Quickstart

Jenkins integrates with other openshift applications.  To use start building
against Jenkins, embed the `jenkins-client` into an existing application.  The
below example will cause app `myapp` to start building against Jenkins.

    $ rhc cartridge add -a myapp -c jenkins-client-1.4

From then on, running a `git push` will cause the build process to happen
inside a Jenkins builder instead of inside your normal application compute
space.

Benefits:

* Archived build information
* No application downtime during the build process
* Failed builds do not get deployed (leaving the previous working version in place). 
* Jenkins builders have additional resources like memory and storage
* A large community of Jenkins plugins

## Building with Jenkins

Building with Jenkins uses dedicated application space that can be larger
then the application runtime space.  Because the build happens in its own
dedicated jail, the running application is not shutdown or changed in any way
until after the build is a success.  If it is not, the current active running
application will continue to run.  However, a failure in the deploy process may
still leave the app partially deployed or inaccessible.  During a build the
following steps take place:

1. User issues a git push
2. Jenkins is notified a new push is ready.
3. A dedicated Jenkins slave (builder) is created.  It can be seen by using
   the 'rhc domain show' command.  The app name will be the same as the originating
   app plus "bldr" tagged onto the end.  Note:  This requires the first 28 chars
   of app name be unique or builders will be shared (can cause issues).
4. Jenkins runs the build
5. Content from originating app is downloaded to the builder app through git and rsync
   (Git for source code and rsync for existing libraries).
6. The cartridge-specific build Shell Task is executed.
7. Jenkins archives build artifacts for later reference
8. After 15 minutes of idle time, the 'build app' will be destroyed and will
   no longer show up with the 'rhc domain show' command.  The build artifacts
   however, will still exist in Jenkins and can be viewed there.

Users can look at the build job by clicking on it in the Jenkins interface and
going to "configure".  It is the Jenkins' build job to stop, sync and start the
application once a build is complete.

For a detailed overview of the OpenShift build/deploy process, consult the 
[OpenShift builds](https://github.com/openshift/origin-server/blob/master/node/README.writing_cartridges.md#openshift-builds)
documentation.

## Markers

Adding marker files to `.openshift/markers` will have the following effects:

    enable_debugging     See 'Debugging Jenkins'


## Debugging Jenkins

The Jenkins server can be configured to accept remote debugger connections. To enable
debugging, create a file `.openshift/markers/enable_debugging` in the Jenkins app
Git repository and restart Jenkins. The debug server will listen on port `7600` for
connections.

Use SSH port forwarding to start a remote debugging session on the server.
The `rhc` command is helpful for this. For example, in a sample Jenkins application
named `jenkins` containing the `enable_debugging` marker, the following command
will automatically enable SSH port forwarding:

    $ rhc port-forward -a jenkins
    Checking available ports...
    Forwarding ports
      Service Connect to            Forward to
      ==== ================ ==== ================
      java 127.0.251.1:7600  =>  127.0.251.1:7600
      java 127.0.251.1:8080  =>  127.0.251.1:8080
    Press CTRL-C to terminate port forwarding

The local debugger can now be attached to `127.0.251.1:7600`.
