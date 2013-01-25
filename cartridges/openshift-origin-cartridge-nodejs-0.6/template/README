Feel free to change or remove this file, it is informational only.

Repo Layout
===========
node_modules/                       - Any Node modules packaged with the app
deplist.txt                         - Deprecated.
package.json                        - npm package descriptor.
npm_global_module_list              - List of globally installed node modules
                                      (on OpenShift)
.openshift/                         - Location for openshift specific files
.openshift/action_hooks/pre_build   - Script that gets run every git push before
                                      the build
.openshift/action_hooks/build       - Script that gets run every git push as
                                      part of the build process (on the CI
                                      system if available)
.openshift/action_hooks/deploy      - Script that gets run every git push after
                                      build but before the app is restarted
.openshift/action_hooks/post_deploy - Script that gets run every git push after
                                      the app is restarted

Notes about layout
==================
Please leave the node_modules and .openshift directories but feel free to
create additional directories if needed.

Note: Every time you push, everything in your remote repo dir gets recreated
      please store long term items (like an sqlite database) in the OpenShift
      data directory, which will persist between pushes of your repo.
      The OpenShift data directory is accessible relative to the remote repo
      directory (../data) or via an environment variable OPENSHIFT_DATA_DIR.


Environment Variables
=====================
OpenShift provides several environment variables to reference for ease
of use.  The following list are some common variables but far from exhaustive:
    process.env.OPENSHIFT_DATA_DIR  - For persistent storage (between pushes)
    process.env.OPENSHIFT_TMP_DIR   - Temp storage (unmodified files deleted after 10 days)

When embedding a database using 'rhc cartridge add', you can reference
environment variables for username, host and password. Example for mysql:
    process.env.OPENSHIFT_MYSQL_DB_HOST      - DB Host
    process.env.OPENSHIFT_MYSQL_DB_PORT      - DB Port
    process.env.OPENSHIFT_MYSQL_DB_USERNAME  - DB Username
    process.env.OPENSHIFT_MYSQL_DB_PASSWORD  - DB Password

When embedding a NoSQL database using 'rhc cartridge add', you can
reference environment variables for username, host and password.
Example for MongoDB:
    process.env.OPENSHIFT_MONGODB_DB_HOST      - NoSQL DB Host
    process.env.OPENSHIFT_MONGODB_DB_PORT      - NoSQL DB Port
    process.env.OPENSHIFT_MONGODB_DB_USERNAME  - NoSQL DB Username
    process.env.OPENSHIFT_MONGODB_DB_PASSWORD  - NoSQL DB Password

To get a full list of environment variables, simply add a line in your
.openshift/action_hooks/build script that says "export" and push.


deplist.txt
===========
This functionality has been deprecated and will soon go away.
package.json is the preferred method to add dependencies.


package.json
============
npm package descriptor - run "npm help json" for more details.

Note: Among other things, this file contains a list of dependencies
      (node modules) to install alongside your application and is processed
      every time you "git push" to your OpenShift application.


Development Mode
================

When you push your code changes to OpenShift, if you want dynamic reloading
of your javascript files in "development" mode, you can either use the
hot_deploy marker (see .openshift/markers/README) or add the following to
package.json.
   "scripts": { "start": "supervisor <relative-path-from-repo-to>/server.js" },

This will run Node with Supervisor - https://npmjs.org/package/supervisor


Local Development + Testing
===========================

You can also develop and test your Node application locally on your machine
(workstation). In order to do this, you will need to perform some
basic setup - install Node + the npm modules that OpenShift has globally
installed:
   1. Collect some information about the environment on OpenShift.
         A. Get Node.js version information:
	      $ ssh $uuid@$appdns node -v
         B. Get list of globally install npm modules
	      $ ssh $uuid@$appdns npm list -g

   2. Ensure that an appropriate version of Node is installed locally.
      This depends on your application. Using the same version would be
      preferable in most cases but your mileage may vary with newer versions.

   3. Install the versions of the Node modules you got in step 1.A
      Use -g if you want to install them globally, the better alternative
      though is to install them in the home directory of the currently
      logged user on your local machine/workstation.
         pushd ~
         npm install [-g] $module_name@$version
         popd


Once you have completed the above setup, you can then run your application
locally by using any one of these commands:
    node server.js
    npm start -d
    supervisor server.js

And then iterate on developing+testing your application.


Additional information
======================
Link to additional information will be here, when we have it :)

