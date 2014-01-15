# OpenShift phpPgAdmin Cartridge

The `phppgadmin` cartridge provides [phpPgAdmin](http://phppgadmin.sourceforge.net/) on OpenShift.

Add this cartridge to an application that already has PostgreSQL:

    rhc cartridge add phppgadmin-5.0 -a APP

Admin user name and password will be displayed.

And access `/phppgadmin` on your application's site and log in with
the credentials given above.
