OpenShift Origin - Node Components for the Idler
============================

Idling of unused gears allows for an efficient means of over-subscribing
machines' resources. Auto-restoring the application upon access further
reduces operational cost.

Installation
----------------------

After installing the openshift-origin-node-util rpm, run the following
commands to make the Idler services active:

```
 # /sbin/chkconfig oddjobd on
 # /sbin/service messagebus restart
 # /sbin/service oddjobd restart
```

Make the following changes to the ```/etc/httpd/conf/httpd.conf``` file.
```
LogFormat "%h %v %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" (%Dus) %X" combined
.
:
CustomLog logs/access_log combined
```

Auto Idling
----------------------

The ```oo-autoidler``` script may be run by cron to idle gears that are
not actively being used. By default, it will idle any gear whose URL has
not been accessed for 24 hours and whose git repo has not been updated
in the last 15 days. The script ```oo-last-access``` is used to compile
the HTTP metrics for each gear.

A basic crontab entry reducing the git update check to 5 days:
```
0 * * * * /usr/sbin/oo-last-access > /var/lib/openshift/last_access.log 2>&1
30 7,19 * * * /usr/sbin/oo-autoidler 5
```

Manual Idling
----------------------

The criteria for Idling gears depends on your usage. Some ideas include:

   * monitor last access of application
   * monitor push of application's git repo
   * time schedule

Some gears may have a marker file ```~/.disable_stale```. These gears are
supporting other gears and should never be idled. A future version of
the OpenShift product will provide a means to idle and safely restore
all the gears of an application.

A cron job or daemon may be used to implement your business logic for
when to idle a gear.  Once a gear has been selected to be idled use the
following command:
```
/usr/sbin/oo-idler -u <gear uuid>
```

Auto Restoring
----------------------

Any access to the gear's URL will restore the application.
```
wget https://application-domain@example.com
```


Manual Restoring
----------------------

A gear may be restored without accessing its URL  using the following
command:
```
/usr/sbin/oo-restorer -u <gear uuid>
```


How does it work?
----------------------

  * oo-idler

    oo-idler stops the application and forwards the application's URL to
    a /var/www/html/restorer.php. Records the application's status as
    'idled'.

    * -u _uuid_ idles the gear
    * -l lists all idled gears on a node
    * -n idles a gear without restarting the node's httpd process. This is
      useful when idling a number of gears, make 1-(n-1) calls with -n and
      then remove -n on the last call to allow the restart httpd.

  * oo-restorer

    oo-restorer restores the application's URL to its original value and
    starts the application. Marks the application's status as 'started'.

    * -u _uuid_ restores the gear

  * oo-admin-ctl-gears

    oo-admin-ctl-gears starts and stops gears.

    * startgear _uuid_
    * stopgear _uuid_

  * /var/www/html/restorer.php

    restorer.php is the place holder php application that is used when
    an application is inactive. It calls oo-restorer-wrapper.sh.

  * oo-restorer-wrapper.sh

    oo-restorer-wrapper.sh queues up the oddjob that will call
    oo-restorer.

  * oddjobd

    The oddjob D-Bus messages are received, and run oo-restorer.
    oddjob is used to safely promote the wrapper call from httpd to
    root privileges.

  * oo-last-access

    oo-last-access compiles a cache of access times for each gear from
    the system http access log. It may be run from cron.  The more
    frequently the script is run the greater predictability of when
    gears will be idled.

  * oo-autoidler

    oo-autoidler uses the cache from ```oo-last-access``` and each gear's
    git repository to determine if that gear is inactive.  Inactive gears
    are idled using ```oo-idler```.

    * _days_ number of days since last git push

