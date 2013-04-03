Repo layout
===========
perl/        - Externally exposed perl code goes
libs/        - Additional libraries
misc/        - For not-externally exposed perl code

.openshift/action_hooks/pre_build   - Script that gets run every git push before the build
.openshift/action_hooks/build       - Script that gets run every git push as part of the build process
                                      (on the CI system if available)
.openshift/action_hooks/deploy      - Script that gets run every git push after build but before the app is restarted
.openshift/action_hooks/post_deploy - Script that gets run every git push after the app is restarted

Notes about layout
==================

Every time you push, everything in your remote repo dir gets recreated,
please store long term items (like an sqlite database) in the OpenShift
data directory, which will persist between pushes of your repo.
The OpenShift data directory is accessible via an environment variable
OPENSHIFT_DATA_DIR.

Cartridge Layout
================
run/         - Various run configs (like httpd pid)
env/         - Environment variables
logs/        - Log data (like httpd access/error logs)
lib/         - Various libraries
bin/setup    - The script to setup the cartridge
bin/build    - Default build script
bin/teardown - Called at cartridge destruction
bin/control  - Init script to start/stop httpd
versions/    - Version data to support multiple perl versions (copied into place
               by setup)

Environment Variables
=====================

OpenShift provides several environment variables to reference for ease
of use.

When embedding a database using 'rhc cartridge add', you can reference
environment variables for username, host and password. Example for mysql:

    os.environ['OPENSHIFT_MYSQL_DB_HOST']      - DB host
    os.environ['OPENSHIFT_MYSQL_DB_PORT']      - DB Port
    os.environ['OPENSHIFT_MYSQL_DB_USERNAME']  - DB Username
    os.environ['OPENSHIFT_MYSQL_DB_PASSWORD']  - DB Password

When embedding a NoSQL database using 'rhc cartridge add', you can
reference environment variables for username, host and password.
Example for MongoDB:
    os.environ['OPENSHIFT_MONGODB_DB_HOST']      - NoSQL DB Host
    os.environ['OPENSHIFT_MONGODB_DB_PORT']      - NoSQL DB Port
    os.environ['OPENSHIFT_MONGODB_DB_USERNAME']  - NoSQL DB Username
    os.environ['OPENSHIFT_MONGODB_DB_PASSWORD']  - NoSQL DB Password

To get a full list of environment variables, simply add a line in your
.openshift/action_hooks/build script that says "export" and push.


Notes about layout
==================

Please leave perl, libs and data directories but feel free to create
additional directories if needed.

Note: Every time you push, everything in your remote repo dir gets
recreated please store long term items (like an sqlite database) in
OPENSHIFT_DATA_DIR which will persist between pushes of your repo.


Notes about deplist.txt
====================

Adding deps to the deplist.txt will have the openshift server automatically
install those deps at git push time.



Notice of Export Control Law
============================

This software distribution includes cryptographic software that is
subject to the U.S. Export Administration Regulations (the "*EAR*")
and other U.S. and foreign laws and may not be exported, re-exported or
transferred (a) to any country listed in Country Group E:1 in Supplement
No. 1 to part 740 of the EAR (currently, Cuba, Iran, North Korea, Sudan
& Syria); (b) to any prohibited destination or to any end user who has
been prohibited from participating in U.S. export transactions by any
federal agency of the U.S. government; or (c) for use in connection with
the design, development or production of nuclear, chemical or biological
weapons, or rocket systems, space launch vehicles, or sounding rockets,
or unmanned air vehicle systems.You may not download this software or
technical information if you are located in one of these countries or
otherwise subject to these restrictions. You may not provide this software
or technical information to individuals or entities located in one of
these countries or otherwise subject to these restrictions. You are also
responsible for compliance with foreign law requirements applicable to
the import, export and use of this software and technical information.
Feel free to change or remove this file, it is informational only.

