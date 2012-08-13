cartridges-new
==============
This is proposed new cartridge format, it does not yet function but comments
are welcome.  See mmcgrath with questions.


Problems
--------
1. People like creating DIY templates, they find it fairly easy and
intutitive even with minimal documentation.  But converting that DIY to an
actual cartridge is daunting.

2.  _LOTS_ of cartridges run as root still.  Creating cartridge setups
that don't run as root is an absolute must for community built cartridge and
it's a good idea in general.

3. The relationship between cartridge, template and gear is complex and non-intuitive

TODO
====

- Proxy Deployment
- IP registry
- All mcollective connections
- Initial Git Repo
- Component level state
- php-5.3/run/pid / status script pid
- Remove version number from cartridge name
  - Add cartridge version somewhere else (maybe manifest?)
- What to do with haproxy.

Cartridge Requirements
----------------------

Looking to build a new cartridge?  These are the current list of *required*
items your cartridge must have to function.  Other bits can be extended.

- ./bin/app_ctl
- ./bin/build.sh
- ./bin/setup
- ./metadata/manifest.yml
- ./metadata/root_files.txt
- ./.env/*

Workflow
========

The concept of configure/deconfigure, etc are now gone.  To 'install' a new
cartridge, first create an empty gear then do the following steps.

    # cp -ad ./php-5.3 ~UUID/                  - Run as root
    # stickshift/unlock.rb UUID php-5.3     - Run as root
    $ ~/php-5.3/setup.py                       - Bulk of work, run as user
    # stickshift/lock.rb UUID php-5.3    - Run as root


New Features provided by the platform (No longer in the cartridge)
==================================================================
- Register a new IP / Port combo
- Expose / conceal hooks
- Proxy Template
- Create owned files (only in the users ~ directory)

Other Changes
=============
- Cartridges can be completely self contained in the gear (can be but don't have to be)
   - This means, once installed, in theory the /usr/libexec/cartridge/ 
     directory could be deleted without impacting the gear
- "Locked" and "Unlocked" mode.  When in unlocked mode, all of the files for a cartridge
    are writable by that user.  This is used for installation (setup.rb runs as the user)
    as well as cartridge creation.  Setting of this mode can be done with the DIY cartridge
    as well as by the cartridge owner but probably not by a normal user.  (So, for example,
    we may not let a user unlock the jboss cartridge, but the broker might do it during an
    update
- ~/.env/ vars moved to ~/php-5.3/env/ and must *NOT* be run as root

Platform vs Cartridge Responsibilities
======================================

Removed/Changed Responsibilities
--------------------------------
- configure / setup
- deconfigure / ?????
- post-remove
- pre-install
- tidy (owned by both platform and cartridge?)


Platform Responsibilities
-------------------------
- add-alias
- conceal-port
- deploy-httpd-proxy
- expose-port
- force-stop
- post-install / post-setup
- remove-alias
- remove-httpd-proxy
- show-port
- update-namespace

Cartridge Responsibilities
--------------------------
- app_ctl to replace basic start/stop operations and be more init script like
  - reload
  - restart
  - start
  - status
  - stop

Undecided
---------
- info
- move (probably mostly platform)
- remove-module
- system-messages
- threaddump
- Connection hooks to be split or included in our 'default' and allowed to be customized?


