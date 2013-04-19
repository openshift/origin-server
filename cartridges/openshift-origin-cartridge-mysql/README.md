# OpenShift MySQL Cartridge

The `mysql` cartridge provides [MySQL](http://www.mysql.com/) on OpenShift.

## Environment Variables

The `mysql` cartridge provides several environment variables to reference for ease
of use:

    OPENSHIFT_MYSQLDB_DB_HOST      The MySQL IP address
    OPENSHIFT_MYSQLDB_DB_PORT      The MySQL port
    OPENSHIFT_MYSQLDB_DB_LOG_DIR   The path to the MySQL log directory

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).
