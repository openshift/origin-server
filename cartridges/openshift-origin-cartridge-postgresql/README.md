Feel free to change or remove this file, it is informational only.

Repo layout
===========
| Directory                           | Purpose                                                                                          |
| ---------                           | -------                                                                                          |
| sql/                                | SQL data or scripts.                                                                             |
| .openshift/action_hooks/pre_build   | Script that gets run every git push before the build                                             |
| .openshift/action_hooks/build       | Script that gets run every git push as part of the build process (on the CI system if available) |
| .openshift/action_hooks/deploy      | Script that gets run every git push after build but before the app is restarted                  |
| .openshift/action_hooks/post_deploy | Script that gets run every git push after the app is restarted                                   |

Environment Variables
=====================
OpenShift provides several environment variables to reference for ease of use.
The following list are some common variables but far from exhaustive.

To get a full list of environment variables, simply SSH into your
application and run `export`.

Directory Variables
-------------------
These variables specify various locations for file storage.
Pay special attention that you are storing persistent data in the
correct location.

| Directory                | Purpose                                               |
| ---------                | -------                                               |
| OPENSHIFT_DATA_DIR       | For persistent storage (between pushes)               |
| OPENSHIFT_TMP_DIR        | Temp storage (unmodified files deleted after 10 days) |
| OPENSHIFT_POSTGRESQL_DIR | Root directory for your Postgres installation         |

Connection/Credential Variables
-------------------------------
The following values are dynamically generated when your application is created.
We strongly recommend that you reference these using their ENV variable name,
and not hard code the value into your applications.

| Variable                           | Notes                                                              |
| ---------                          | -------                                                            |
| OPENSHIFT_POSTGRESQL_DB_HOST       | Numeric host address                                               |
| OPENSHIFT_POSTGRESQL_DB_PORT       | Port                                                               |
| OPENSHIFT_POSTGRESQL_DB_USERNAME   | DB Username                                                        |
| OPENSHIFT_POSTGRESQL_DB_PASSWORD   | DB Password                                                        |
| OPENSHIFT_POSTGRESQL_DB_LOG_DIR    | Directory for log files                                            |
| OPENSHIFT_POSTGRESQL_DB_PID        | PID of current Postgres server                                     |
| OPENSHIFT_POSTGRESQL_DB_SOCKET_DIR | Postgres socket location                                           |
| OPENSHIFT_POSTGRESQL_DB_URL        | Full server URL of the form "postgresql://user:password@host:port" |

Notes about layout
==================
Please leave `sql` and `data` directories but feel free to create additional
directories if needed.

Note: Every time you push, everything in your remote repo dir gets recreated
please store long term items in `$OPENSHIFT_DATA_DIR` which will persist between pushes of
your repo.
