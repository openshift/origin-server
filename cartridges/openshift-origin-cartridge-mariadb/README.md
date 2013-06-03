# OpenShift MariaDB Cartridge

The `mariadb` cartridge provides [MariaDB](http://mariadb.org/) on OpenShift.

## Environment Variables

The `mariadb` cartridge provides several environment variables to reference for ease
of use:

    OPENSHIFT_MARIADB_DB_HOST      The MySQL IP address
    OPENSHIFT_MARIADB_DB_PORT      The MySQL port
    OPENSHIFT_MARIADB_DB_LOG_DIR   The path to the MySQL log directory

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).
