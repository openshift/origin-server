# OpenShift Perl Cartridge

The `perl` cartridge provides [Perl](http://www.perl.org/) on OpenShift.

## Template Repository Layout

    perl/                 For not-externally exposed perl code
    libs/                 Additional libraries
    misc/                 For not-externally exposed perl code
    .openshift/           Location for OpenShift specific files
      action_hooks/       See the Action Hooks documentation [1]
      markers/            See the Markers section [2]

\[1\] [Action Hooks documentation](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md#action-hooks)
\[2\] [Markers](#markers)

Please leave the `perl`, `libs` and `data` directories but feel free to create
additional directories if needed.

Note: Every time you push, everything in your remote repo dir gets
recreated. Please store long term items (like an sqlite database) in
`OPENSHIFT_DATA_DIR` which will persist between pushes of your repo.

## Cartridge Layout

    run/                  Various run configs (like httpd pid)
    env/                  Environment variables
    logs/                 Log data (like httpd access/error logs)
    lib/                  Various libraries
    bin/setup             The script to setup the cartridge
    bin/build             Default build script
    bin/teardown          Called at cartridge destruction
    bin/control           Init script to start/stop httpd
    versions/             Version data to support multiple perl versions (copied into place by setup)

## Environment Variables

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).

## Markers

Adding marker files to `.openshift/markers` will have the following effects:

    force_clean_build     Will remove all previous perl deps and start installing
                          required deps from scratch

    enable_cpan_tests     Will install all the cpan packages and run their tests

    hot_deploy            Will prevent the apache process from being restarted during
                          build/deployment

    disable_auto_scaling  Will prevent scalable applications from scaling up 
                          or down according to application load.
