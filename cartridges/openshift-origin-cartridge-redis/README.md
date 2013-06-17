# OpenShift Redis Cartridge

The `redis` cartridge provides [Redis](http://www.mongodb.org/) on OpenShift.

## Environment Variables

The `redis` cartridge provides several environment variables to reference for ease
of use:

    OPENSHIFT_REDIS_DB_HOST      The Redis IP address
    OPENSHIFT_REDIS_DB_PORT      The Redis port
    OPENSHIFT_REDIS_DB_LOG_DIR   The path to the Redis log directory

For more information about environment variables, consult the
[OpenShift Application Author Guide](https://github.com/openshift/origin-server/blob/master/node/README.writing_applications.md).
