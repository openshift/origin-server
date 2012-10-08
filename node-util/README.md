OpenShift Origin - Node Components for the Idler
============================

Idling of unused gears allows for an efficient means of over-subscribing
machines' resources. Auto-restoring the application upon access further
reduces operational cost.


Idling
----------------------

The criteria for Idling gears depends on your usage. Some ideas include:

   * monitor last access of application
   * monitor push of application's git repo
   * time schedule

Some gears may have a marker file `~/.disable_stale`. These gears are
supporting other gears and should never be idled. A future version of
the OpenShift product will provide a means to idle and safely restore
all the gears of an application.

A cron job or daemon may be used to implement your business logic for
when to idle a gear.  Once a gear has been selected to be idled use the
following command:

```/usr/bin/oo-idler -u <gear uuid>```

Auto Restoring
----------------------

Any access to the gear's URL will restore the application.

```wget https://application-domain@example.com```


Manual Restoring
----------------------

A gear may be restored without accessing it's URL  using the following
command:

```/usr/bin/oo-restorer -u <gear uuid>```


How does it work?
----------------------

  * oo-idler

    oo-idler stops the application and forwards the application's URL to
    a /var/www/html/restorer.php. Records the application's status as
    'idled'.

    * -u <uuid> idles the gear
    * -l lists all idled gears on a node
    * -n idles a gear without restarting the node's httpd process. This is
      useful when idling a number of gears, make 1-(n-1) calls with -n and
      then remove -n on the last call to allow the restart httpd.

  * oo-restorer

    oo-restorer restores the application's URL to it's original value and
    starts the application. Marks the application's status as 'started'.

    * -u <uuid> restores the gear

  * oo-admin-ctl-gears

    oo-admin-ctl-gears starts and stops gears.

    * startgear <uuid>
    * stopgear <uuid>

  * /var/www/html/restorer.php

    restorer.php is the place holder php application that is used when
    an application is inactive. It calls oo-restorer-wrapper.sh.

  * oo-restorer-wrapper.sh

    oo-restorer-wrapper.sh queues up the oddjob that will call
    oo-restorer.

  * oddjobd

    The oddjob D-Bus messages are received, and run oo-restorer.
    oddjob is used to safely promote the wrapper call from apache to
    root privileges.
