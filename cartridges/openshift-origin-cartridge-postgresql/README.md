# OpenShift PostgreSQL Cartridge

The `postgresql` cartridge provides [PostgreSQL](http://www.postgresql.com/) on OpenShift.

## Template Repository Layout

    sql/     SQL data or scripts.


NOTE: Please leave `sql` and `data` directories but feel free to create additional
directories if needed.

## Environment Variables

The `postgresql` cartridge provides several environment variables to reference for ease
of use:

    OPENSHIFT_POSTGRESQL_DB_HOST        Numeric host address
    OPENSHIFT_POSTGRESQL_DB_PORT        Port
    OPENSHIFT_POSTGRESQL_DB_USERNAME    DB Username
    OPENSHIFT_POSTGRESQL_DB_PASSWORD    DB Password
    OPENSHIFT_POSTGRESQL_DB_LOG_DIR     Directory for log files
    OPENSHIFT_POSTGRESQL_DB_PID         PID of current Postgres server
    OPENSHIFT_POSTGRESQL_DB_SOCKET_DIR  Postgres socket location
    OPENSHIFT_POSTGRESQL_DB_URL         Full server URL of the form "postgresql://user:password@host:port"
    OPENSHIFT_POSTGRESQL_VERSION        PostgreSQL version in the form `X.Y`

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).
