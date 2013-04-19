# OpenShift DIY Cartridge

The `diy` cartridge provides a minimal, free-form scaffolding which leaves all
details of the cartridge to the application developer.

## Get started
1. Add framework of choice to your repo.
2. Modify `.openshift/action_hooks/start` to start your application.
   The application is required to bind to `$OPENSHIFT_DIY_IP:$OPENSHIFT_DIY_PORT`.
3. Modify `.openshift/action_hooks/stop` to stop your application.
4. Commit and push your changes.

## Repo layout

    static/           Externally exposed static content goes here
    .openshift/
      action_hooks/   See the Action Hooks documentation [1]
        start         Custom action hook used to start your application
        stop          CUstom action hook to stop your application

\[1\] [Action Hooks documentation](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md#action-hooks)

Note: Please leave the `static` directory in place (alter but do not delete) but feel
free to create additional directories if needed.

Every time you push, everything in your remote repo dir gets recreated.
Please store long term items (like an sqlite database) in the OpenShift
data directory, which will persist between pushes of your repo.
The OpenShift data directory is accessible via `$OPENSHIFT_DATA_DIR`.

## Environment Variables

The `diy` cartridge provides the following environment variables to reference for ease
of use:

    OPENSHIFT_DIY_IP      The IP address assigned to the application
    OPENSHIFT_DIY_PORT    The port assigned to the the application

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).
