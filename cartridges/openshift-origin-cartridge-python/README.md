# OpenShift Python Cartridge

The `python` cartridge provides [Python](http://www.python.org/) on OpenShift.

## Template Repository Layout

    wsgi/                  Externally exposed wsgi code goes
    wsgi/static/           Public static content gets served here
    libs/                  Additional libraries
    data/                  For not-externally exposed wsgi code
    setup.py               Standard setup.py, specify deps here
    .openshift/            Location for OpenShift specific files
      action_hooks/        See the Action Hooks documentation [1]
      markers/             See the Markers section [2]

\[1\] [Action Hooks documentation](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md#action-hooks)
\[2\] [Markers](#markers)

### Repository layout notes

Please leave the `wsgi`, `libs` and `data` directories but feel free to create additional
directories if needed.

Every time you push, everything in your remote repo dir gets recreated, please
store long term items (like an sqlite database) in the OpenShift data
directory, which will persist between pushes of your repo.
The OpenShift data directory is accessible relative to the remote repo via an
environment variable `OPENSHIFT_DATA_DIR`.

### Notes about setup.py

Adding deps to the `install_requires` will cause the cartirdge to install those
deps at git push time.

## Cartridge Layout

    run/           Various run configs (like httpd pid)
    env/           Environment variables
    logs/          Log data (like httpd access/error logs)
    lib/           Various libraries
    bin/setup      The script to setup the cartridge
    bin/build      Default build script
    bin/teardown   Called at cartridge descruction
    bin/control    Init script to start/stop httpd
    versions/      Version data to support multiple python versions (copied into place
                   by setup

## Environment Variables

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).
