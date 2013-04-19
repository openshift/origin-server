# OpenShift PHP Cartridge

The `php` cartridge provides [PHP](http://www.php.net) on OpenShift.

## Template Repository Layout

    php/                   Externally exposed PHP code goes here
    libs/                  Additional libraries
    misc/                  For PHP code that should not be accessible by end users
    deplist.txt            List of pears to install
    .openshift/            Location for OpenShift specific files
      action_hooks/        See the Action Hooks documentation [1]
      markers/             See the Markers section [2]

\[1\] [Action Hooks documentation](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md#action-hooks)
\[2\] [Markers](#markers)

OpenShift will look for the `php` and `libs` directories when serving your 
application. index.php will handle requests to the root URL of your 
application. You can create new directories as needed.

Note: Every time you push, everything in your remote repo dir is recreated.
Please store long term items (like an sqlite database) in the OpenShift
data directory, which will persist between pushes of your repo.
The OpenShift data directory is accessible relative to the remote repo
directory (../data) or via an environment variable `OPENSHIFT_DATA_DIR`.


## Environment Variables

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).


## deplist.txt

A list of pears to install, line by line on the server.  This will happen when
the user git pushes.

## Markers

Adding marker files to `.openshift/markers` will have the following effects:

    force_clean_build     Will remove all previous perl deps and start installing
                          required deps from scratch

    hot_deploy            Will prevent the apache process from being restarted during
                          build/deployment

    disable_auto_scaling  Will prevent scalable applications from scaling up 
                          or down according to application load.
