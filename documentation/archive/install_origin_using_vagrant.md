# @markup markdown
# @title Installing OpenShift Origin using Vagrant

# Installing OpenShift Origin using Vagrant

This document describes how to create a private PaaS service for local development of OpenShift Origin. We will be building the PaaS using source OpenShift Origin nightly RPMs Vagrant, and Puppet.

Vagrant is a very useful utility which allows you to quickly spin-up VMs in VirtaulBox based on a template file.

## Creating the Virtual Box VM using Vagrant

1. Download and install [VirtaulBox](https://www.virtualbox.org/)
2. Download and install [Vagrant](http://www.vagrantup.com/)
3. Download and extract the [OpenShift Origin Vagrant template](https://github.com/openshift/puppet-openshift_origin/archive/master.zip)

        curl -s https://nodeload.github.com/openshift/puppet-openshift_origin/legacy.tar.gz/master | tar zxf - --strip 1 '**/test' && mv test origin_vagrant

4. Spin up the VM using vagrant

        cd origin_vagrant ; vagrant up

5. Once the VM has spun up, ssh into the VM

        vagrant ssh

## Vagrant output

Below is the output of the commands running on my desktop:

    Helios:Documents kraman$ curl -s https://nodeload.github.com/openshift/puppet-openshift_origin/legacy.tar.gz/master | tar zxf - --strip 1 '**/test' && mv test origin_vagrant
    Helios:Documents kraman$ cd origin_vagrant ; vagrant up
    [default] Box f18 was not found. Fetching box from specified URL...
    [vagrant] Downloading with Vagrant::Downloaders::HTTP...
    [vagrant] Downloading box: https://mirror.openshift.com/pub/vagrant/boxes/fedora-sphericalcow.box
    [vagrant] Extracting box...
    [vagrant] Verifying box...
    [vagrant] Cleaning up downloaded box...
    [default] Importing base box 'f18'...
    [default] Matching MAC address for NAT networking...
    [default] Clearing any previously set forwarded ports...
    [default] You are trying to forward to privileged ports (ports <= 1024). Most
    operating systems restrict this to only privileged process (typically
    processes running as an administrative user). This is a warning in case
    the port forwarding doesn't work. If any problems occur, please try a
    port higher than 1024.
    [default] Forwarding ports...
    [default] -- 22 => 2222 (adapter 1)
    [default] -- 80 => 80 (adapter 1)
    [default] -- 443 => 443 (adapter 1)
    [default] -- 53 => 53 (adapter 1)
    [default] Creating shared folders metadata...
    [default] Clearing any previously set network interfaces...
    [default] Booting VM...
    [default] Waiting for VM to boot. This can take a few minutes.
    [default] VM booted and ready for use!
    [default] Setting host name...
    [default] Mounting shared folders...
    [default] -- v-root: /vagrant
    [default] -- manifests: /home/vagrant/manifests
    [default] Running provisioner: Vagrant::Provisioners::Shell...
    Notice: Preparing to uninstall 'openshift-openshift_origin' ...
    
    Error: Could not uninstall module 'openshift-openshift_origin'
      Module 'openshift-openshift_origin' is not installed
    
    Notice: Preparing to install into /etc/puppet/modules ...
    
    Notice: Downloading from https://forge.puppetlabs.com ...
    
    Notice: Installing -- do not interrupt ...
    
    /etc/puppet/modules
      openshift-openshift_origin (v0.1.1)
        puppetlabs-ntp (v0.2.0)
        puppetlabs-stdlib (v3.2.0)
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/facter_dot_d.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/root_home.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/pe_version.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/puppet_vardir.rb
    
    Info: Loading facts in /etc/puppet/modules/openshift_origin/plugins/facter/openshift_mount.rb
    
    Info: Loading facts in /etc/puppet/modules/openshift_origin/plugins/facter/firewalld.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/facter_dot_d.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/root_home.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/pe_version.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/puppet_vardir.rb
    
    Info: Loading facts in /etc/puppet/modules/openshift_origin/plugins/facter/openshift_mount.rb
    
    Info: Loading facts in /etc/puppet/modules/openshift_origin/plugins/facter/firewalld.rb
    
    Info: Applying configuration version '1361523351'
    Notice: /Stage[main]//Augeas[network setup]/returns: executed successfully
    
    Notice: /Stage[main]//Package[bind]/ensure: created
    Notice: /Stage[main]//Exec[generate tsig key]/returns: executed successfully
    Info: Creating state file /var/lib/puppet/state/state.yaml
    
    Notice: Finished catalog run in 54.75 seconds
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/facter_dot_d.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/root_home.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/pe_version.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/puppet_vardir.rb
    
    Info: Loading facts in /etc/puppet/modules/openshift_origin/plugins/facter/openshift_mount.rb
    
    Info: Loading facts in /etc/puppet/modules/openshift_origin/plugins/facter/firewalld.rb
    
    Warning: Config file /etc/puppet/hiera.yaml not found, using Hiera defaults
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/facter_dot_d.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/root_home.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/pe_version.rb
    
    Info: Loading facts in /etc/puppet/modules/stdlib/lib/facter/puppet_vardir.rb
    
    Info: Loading facts in /etc/puppet/modules/openshift_origin/plugins/facter/openshift_mount.rb
    Info: Loading facts in /etc/puppet/modules/openshift_origin/plugins/facter/firewalld.rb
    Info: Applying configuration version '1361523408'
    
    Notice: /Stage[main]/Openshift_origin::Named/Package[bind-utils]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Selboolean[allow_polyinstantiation]/value: value changed 'off' to 'on'
    Notice: /Stage[main]/Openshift_origin::Node/Selboolean[httpd_execmem]/value: value changed 'off' to 'on'
    Notice: /Stage[main]/Openshift_origin::Node/Selboolean[httpd_can_network_relay]/value: value changed 'off' to 'on'
    Notice: /Stage[main]/Openshift_origin/Exec[Open port for SSH]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Node/Exec[Open HTTP port for Node-webproxy]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Named/Exec[Open UDP port for BIND]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin/Augeas[network setup]/returns: executed successfully
    
    Notice: /Stage[main]/Openshift_origin::Node/Exec[Open HTTPS port for Node-webproxy]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Node/Selboolean[httpd_read_user_content]/value: value changed 'off' to 'on'
    Notice: /Stage[main]/Openshift_origin::Node/Exec[Update sshd configs]/returns: executed successfully
    
    Notice: /Stage[main]/Openshift_origin::Node/Selboolean[httpd_enable_homedirs]/value: value changed 'off' to 'on'
    Info: FileBucket adding {md5}a269bd98af0d73759e72d873c66a77b2
    
    Info: /File[sysctl config tweaks]: Filebucketed /etc/sysctl.conf to puppet with sum a269bd98af0d73759e72d873c66a77b2
    
    Notice: /File[sysctl config tweaks]/content: content changed '{md5}a269bd98af0d73759e72d873c66a77b2' to '{md5}9b8f0706975c0be4c57673e0f4f74cb8'
    
    Notice: /Stage[main]/Openshift_origin/Exec[Open port for HTTP]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Named/Selboolean[named_write_master_zones]/value: value changed 'off' to 'on'
    Notice: /Stage[main]/Ntp/Package[ntp]/ensure: created
    Info: /Stage[main]/Ntp/Package[ntp]: Scheduling refresh of Service[ntp]
    Info: FileBucket adding {md5}52238166434bcd6836bf21c6cf7f34ea
    
    Info: /File[/etc/ntp.conf]: Filebucketed /etc/ntp.conf to puppet with sum 52238166434bcd6836bf21c6cf7f34ea
    
    Notice: /File[/etc/ntp.conf]/content: content changed '{md5}52238166434bcd6836bf21c6cf7f34ea' to '{md5}e15769b1934723e86f401747bedbd05f'
    
    Info: /File[/etc/ntp.conf]: Scheduling refresh of Service[ntp]
    
    Notice: /Stage[main]/Openshift_origin::Node/Exec[jenkins repo key]/returns: executed successfully
    Info: create new repo jenkins in file /etc/yum.repos.d/jenkins.repo
    
    Notice: /Stage[main]/Openshift_origin::Node/Yumrepo[jenkins]/baseurl: baseurl changed '' to 'http://pkg.jenkins-ci.org/redhat'
    
    Notice: /Stage[main]/Openshift_origin::Node/Yumrepo[jenkins]/enabled: enabled changed '' to '1'
    
    Notice: /Stage[main]/Openshift_origin::Node/Yumrepo[jenkins]/gpgcheck: gpgcheck changed '' to '1'
    
    Info: changing mode of /etc/yum.repos.d/jenkins.repo from 600 to 644
    
    Info: create new repo openshift-origin-deps in file /etc/yum.repos.d/openshift-origin-deps.repo
    
    Notice: /Stage[main]/Openshift_origin/Yumrepo[openshift-origin-deps]/baseurl: baseurl changed '' to 'https://mirror.openshift.com/pub/openshift-origin/fedora-19/x86_64/'
    
    Notice: /Stage[main]/Openshift_origin/Yumrepo[openshift-origin-deps]/enabled: enabled changed '' to '1'
    
    Notice: /Stage[main]/Openshift_origin/Yumrepo[openshift-origin-deps]/gpgcheck: gpgcheck changed '' to '0'
    
    Info: changing mode of /etc/yum.repos.d/openshift-origin-deps.repo from 600 to 644
    
    Notice: /Stage[main]/Openshift_origin::Mongo/Package[mongodb-server]/ensure: created
    Notice: /Stage[main]/Openshift_origin/Package[mcollective]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Service[mcollective]/enable: enable changed 'false' to 'true'
    Info: FileBucket adding {md5}14b5dc8b6e31671be6d58209765619ad
    
    Info: /File[mcollective server config]: Filebucketed /etc/mcollective/server.cfg to puppet with sum 14b5dc8b6e31671be6d58209765619ad
    
    Notice: /File[mcollective server config]/content: content changed '{md5}14b5dc8b6e31671be6d58209765619ad' to '{md5}8adc2c6d09abc022b68c70ed9202074d'
    
    Notice: /File[mcollective server config]/mode: mode changed '0640' to '0644'
    
    Info: FileBucket adding {md5}d74fd9a4ef98d7dbe407592a1f601420
    
    Info: /File[Temporarily Disable mongo auth]: Filebucketed /etc/mongodb.conf to puppet with sum d74fd9a4ef98d7dbe407592a1f601420
    
    Notice: /File[Temporarily Disable mongo auth]/content: content changed '{md5}d74fd9a4ef98d7dbe407592a1f601420' to '{md5}f9e027424a19fd9dc44958e92d2c9e8b'
    
    Info: /File[Temporarily Disable mongo auth]: Scheduling refresh of Exec[start mongodb]
    
    Notice: /Stage[main]/Openshift_origin::Broker/Package[tzinfo]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[bundler]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[netrc]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[rake]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[diff-lcs]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[activesupport]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[rubygem-passenger]/ensure: created
    Info: /Stage[main]/Openshift_origin::Broker/Package[rubygem-passenger]: Scheduling refresh of Exec[fixfiles rubygem-passenger]
    Notice: /Stage[main]/Openshift_origin::Broker/Package[railties]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[mod_passenger]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[mime-types]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[mongo]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[actionmailer]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[mocha]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Exec[fixfiles rubygem-passenger]: Triggered 'refresh' from 1 events
    Notice: /Stage[main]/Openshift_origin::Broker/Package[xml-simple]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[regin]/ensure: created
    
    Notice: /Stage[main]/Openshift_origin::Broker/Package[mongodb-devel]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[minitest]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Selboolean[allow_ypbind]/value: value changed 'off' to 'on'
    Notice: /Stage[main]/Openshift_origin::Broker/Package[rails]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[origin]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[mongoid]/ensure: created
    Notice: /File[/var/log/passenger-analytics]/owner: owner changed 'root' to 'apache'
    
    Notice: /File[/var/log/passenger-analytics]/group: group changed 'root' to 'apache'
    
    Notice: /File[/var/log/passenger-analytics]/mode: mode changed '0755' to '0750'
    
    Notice: /Stage[main]/Openshift_origin::Broker/Package[mysql-devel]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[dnsruby]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Named/Exec[Open TCP port for BIND]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Broker/Exec[Generate self signed keys for broker auth]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Broker/Package[term-ansicolor]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Selboolean[httpd_run_stickshift]/value: value changed 'off' to 'on'
    Notice: /Stage[main]/Openshift_origin/Exec[Open port for HTTPS]/returns: executed successfully
    
    Notice: /Stage[main]/Openshift_origin::Broker/Package[simplecov]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Named/Exec[create rndc.key]/returns: executed successfully
    Notice: /File[/etc/rndc.key]/group: group changed 'root' to 'named'
    
    Notice: /File[/etc/rndc.key]/mode: mode changed '0600' to '0640'
    
    Notice: /File[/etc/rndc.key]/seluser: seluser changed 'unconfined_u' to 'system_u'
    
    Notice: /File[/etc/rndc.key]/seltype: seltype changed 'etc_t' to 'dnssec_t'
    
    Notice: /Stage[main]/Openshift_origin::Broker/Selboolean[httpd_verify_dns]/value: value changed 'off' to 'on'
    
    Notice: /Stage[main]/Openshift_origin::Broker/Package[webmock]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Activemq/Exec[Open port for ActiveMQ]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Activemq/Package[activemq-client]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[open4]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Mongo/Exec[start mongodb]: Triggered 'refresh' from 1 events
    Info: /Stage[main]/Openshift_origin::Mongo/Exec[start mongodb]: Scheduling refresh of Exec[set mongo admin password]
    Info: /Stage[main]/Openshift_origin::Mongo/Exec[start mongodb]: Scheduling refresh of Exec[create mongo auth plugin admin user]
    Notice: /Stage[main]/Openshift_origin::Mongo/Exec[create mongo auth plugin admin user]: Triggered 'refresh' from 1 events
    Info: /Stage[main]/Openshift_origin::Mongo/Exec[create mongo auth plugin admin user]: Scheduling refresh of Exec[re-enable mongo]
    Notice: /Stage[main]/Openshift_origin::Mongo/Exec[set mongo admin password]: Triggered 'refresh' from 1 events
    Info: /Stage[main]/Openshift_origin::Mongo/Exec[set mongo admin password]: Scheduling refresh of Exec[re-enable mongo]
    Notice: /Stage[main]/Openshift_origin::Node/Selboolean[httpd_can_network_connect]/value: value changed 'off' to 'on'
    Notice: /Stage[main]/Openshift_origin::Mongo/Exec[Open port for MongoDB]/returns: executed successfully
    Notice: /Stage[main]/Ntp/Service[ntp]/ensure: ensure changed 'stopped' to 'running'
    Notice: /Stage[main]/Ntp/Service[ntp]: Triggered 'refresh' from 2 events
    Notice: /Stage[main]/Openshift_origin::Broker/Package[state_machine]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[moped]/ensure: ensure changed '["1.4.2"]' to '1.3.2'
    Notice: /Stage[main]/Openshift_origin/Service[httpd]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Mongo/Exec[re-enable mongo]: Triggered 'refresh' from 2 events
    Info: /Stage[main]/Openshift_origin::Mongo/Exec[re-enable mongo]: Scheduling refresh of Service[mongod]
    Notice: /Stage[main]/Openshift_origin::Mongo/Service[mongod]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Mongo/Service[mongod]: Triggered 'refresh' from 1 events
    Notice: /File[/var/named]/owner: owner changed 'root' to 'named'
    
    Notice: /File[named key]/ensure: defined content as '{md5}4636fc7c3c65f2f21451d44423dee010'
    
    Notice: /File[/var/named/forwarders.conf]/ensure: defined content as '{md5}767ba2e5abaa008ad8a853b9c84b8006'
    
    Notice: /File[/var/named/dynamic]/mode: mode changed '0770' to '0750'
    
    Notice: /File[dynamic zone]/ensure: defined content as '{md5}dfccfa5662649f85686064da0d678ab1'
    
    Info: FileBucket adding {md5}f50aac69f1b2653a7aa41b6ddb4c6f4c
    
    Info: /File[Named configs]: Filebucketed /etc/named.conf to puppet with sum f50aac69f1b2653a7aa41b6ddb4c6f4c
    
    Notice: /File[Named configs]/content: content changed '{md5}f50aac69f1b2653a7aa41b6ddb4c6f4c' to '{md5}6c3c24f0784e8fbab6ef98ec743e12e2'
    
    Notice: /File[Named configs]/mode: mode changed '0640' to '0644'
    
    Info: /File[Named configs]: Scheduling refresh of Service[named]
    
    Info: /File[Named configs]: Scheduling refresh of Service[named]
    
    Notice: /Stage[main]/Openshift_origin::Named/Exec[named restorecon]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Named/Service[named]/ensure: ensure changed 'stopped' to 'running'
    Notice: /Stage[main]/Openshift_origin::Named/Service[named]: Triggered 'refresh' from 2 events
    Notice: /File[mcollective client config]/ensure: created
    
    Notice: /Stage[main]/Openshift_origin::Broker/Package[multi_json]/ensure: ensure changed '["1.6.1"]' to '1.5.0'
    Notice: /Stage[main]/Openshift_origin/Service[network]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Broker/Package[rest-client]/ensure: created
    Info: create new repo openshift-origin in file /etc/yum.repos.d/openshift-origin.repo
    Notice: /Stage[main]/Openshift_origin/Yumrepo[openshift-origin-packages]/baseurl: baseurl changed '' to 'https://mirror.openshift.com/pub/openshift-origin/nightly/fedora-19/latest/x86_64/'
    
    Notice: /Stage[main]/Openshift_origin/Yumrepo[openshift-origin-packages]/enabled: enabled changed '' to '1'
    
    Notice: /Stage[main]/Openshift_origin/Yumrepo[openshift-origin-packages]/gpgcheck: gpgcheck changed '' to '0'
    
    Info: changing mode of /etc/yum.repos.d/openshift-origin.repo from 600 to 644
    
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-mongodb]/ensure: created
    Notice: /Stage[main]/Openshift_origin/Package[rhc]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-jenkins-client]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-perl]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[rubygem-openshift-origin-dns-nsupdate]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-diy]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-jenkins]/ensure: created
    Notice: /File[plugin openshift-origin-dns-nsupdate.conf]/ensure: defined content as '{md5}7704a8bfe2abaf76e9841d76a71ce07d'
    
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-haproxy]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-port-proxy]/ensure: created
    
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-python]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Exec[Restoring SELinux contexts]/returns: executed successfully
    
    Info: FileBucket adding {md5}cbd4bafffd7029c62485969acb059c77
    
    Info: /File[openshift node config]: Filebucketed /etc/openshift/node.conf to puppet with sum cbd4bafffd7029c62485969acb059c77
    
    Notice: /File[openshift node config]/content: content changed '{md5}cbd4bafffd7029c62485969acb059c77' to '{md5}6ede9fd8ab949752764cabc405bbb63b'
    
    Info: FileBucket adding {md5}bad9c0612287ec22998becdf24e2b54b
    
    Info: /File[/etc/openshift/express.conf]: Filebucketed /etc/openshift/express.conf to puppet with sum bad9c0612287ec22998becdf24e2b54b
    
    Notice: /File[/etc/openshift/express.conf]/content: content changed '{md5}bad9c0612287ec22998becdf24e2b54b' to '{md5}3269dfca42bf7d18a65716379c0f0645'
    
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-phpmyadmin]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-php]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-ruby]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-msg-node-mcollective]/ensure: created
    Notice: /File[openshift node pam-namespace sandbox.conf]/ensure: created
    
    Notice: /File[openshift node pam-namespace tmp.conf]/ensure: created
    
    Notice: /File[openshift node pam-namespace vartmp.conf]/ensure: created
    
    Info: FileBucket adding {md5}da714d1ef1b85471f3bb1a83daa7a88b
    
    Info: /File[openshift node pam runuser-l]: Filebucketed /etc/pam.d/runuser-l to puppet with sum da714d1ef1b85471f3bb1a83daa7a88b
    
    Notice: /File[openshift node pam runuser-l]/content: content changed '{md5}da714d1ef1b85471f3bb1a83daa7a88b' to '{md5}e796aacdcc91ee5bcc46007b69763d05'
    
    Info: FileBucket adding {md5}5b7b390767c45395b78100e64dfb90f8
    
    Info: /File[openshift node pam sshd]: Filebucketed /etc/pam.d/sshd to puppet with sum 5b7b390767c45395b78100e64dfb90f8
    
    Notice: /File[openshift node pam sshd]/content: content changed '{md5}5b7b390767c45395b78100e64dfb90f8' to '{md5}ea3f11c56e6fc90afcb1be46792efb0b'
    
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-python]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-mysql]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-node-util]/ensure: created
    
    Notice: /Stage[main]/Openshift_origin::Node/Exec[Initialize quota DB]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Console/Package[rubygem-openshift-origin-console]/ensure: created
    Info: /Stage[main]/Openshift_origin::Console/Package[rubygem-openshift-origin-console]: Scheduling refresh of Exec[Console gem dependencies]
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-cron]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[rubygem-openshift-origin-auth-mongo]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[rubygem-openshift-origin-dns-bind]/ensure: created
    
    Info: FileBucket adding {md5}3388e442376e703bd618200f4ca34148
    
    Info: /File[openshift node pam system-auth-ac]: Filebucketed /etc/pam.d/system-auth-ac to puppet with sum 3388e442376e703bd618200f4ca34148
    
    Notice: /File[openshift node pam system-auth-ac]/content: content changed '{md5}3388e442376e703bd618200f4ca34148' to '{md5}480d15941ba610bec38fe124102fe007'
    
    Notice: /File[openshift node pam system-auth-ac]/seltype: seltype changed 'etc_runtime_t' to 'etc_t'
    
    Notice: /Stage[main]/Openshift_origin::Broker/Package[rubygem-openshift-origin-msg-broker-mcollective]/ensure: created
    Notice: /File[Auth plugin config]/ensure: created
    
    Info: FileBucket adding {md5}951e804edc88857ad7fbce0fc515e23f
    
    Info: /File[openshift node pam su]: Filebucketed /etc/pam.d/su to puppet with sum 951e804edc88857ad7fbce0fc515e23f
    
    Notice: /File[openshift node pam su]/content: content changed '{md5}951e804edc88857ad7fbce0fc515e23f' to '{md5}6028d8224256c9ec5e06a45ebc02048a'
    
    Notice: /Stage[main]/Openshift_origin::Broker/Exec[rsync ssh key]/returns: executed successfully
    Info: FileBucket adding {md5}d797843b1ac6a9ce66ce63dd7c30ce7f
    
    Info: /File[openshift broker.conf]: Filebucketed /etc/openshift/broker.conf to puppet with sum d797843b1ac6a9ce66ce63dd7c30ce7f
    
    Notice: /File[openshift broker.conf]/content: content changed '{md5}d797843b1ac6a9ce66ce63dd7c30ce7f' to '{md5}982bf6e2252385c3b7152bad463cbf8a'
    
    Notice: /File[openshift broker.conf]/mode: mode changed '0640' to '0644'
    
    Notice: /File[/etc/openshift/development]/ensure: defined content as '{md5}d41d8cd98f00b204e9800998ecf8427e'
    
    Notice: /Stage[main]/Openshift_origin::Broker/Service[openshift-broker]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-nodejs]/ensure: created
    Notice: /File[mcollective broker plugin config]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[openshift-origin-broker-util]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Console/Package[openshift-origin-console]/ensure: created
    Info: /Stage[main]/Openshift_origin::Console/Package[openshift-origin-console]: Scheduling refresh of Exec[Console gem dependencies]
    Info: FileBucket adding {md5}c65320a6de2d6aeea0d11e9058148389
    Info: /File[openshift console.conf]: Filebucketed /etc/openshift/console.conf to puppet with sum c65320a6de2d6aeea0d11e9058148389
    Notice: /File[openshift console.conf]/content: content changed '{md5}c65320a6de2d6aeea0d11e9058148389' to '{md5}c68c49e66d6748c7dfeaaa355609fb51'
    Notice: /File[openshift console.conf]/mode: mode changed '0640' to '0644'
    Info: /File[openshift console.conf]: Scheduling refresh of Exec[Console gem dependencies]
    
    Info: /File[openshift console.conf]: Scheduling refresh of Exec[Console gem dependencies]
    
    Notice: /Stage[main]/Openshift_origin::Console/Exec[Console gem dependencies]: Triggered 'refresh' from 4 events
    
    Notice: /Stage[main]/Openshift_origin::Console/Service[openshift-console]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Node/File[broker and console route for node]/ensure: created
    
    Notice: /Stage[main]/Openshift_origin::Node/Exec[regen node routes]/returns: executed successfully
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-postgresql]/ensure: created
    Notice: /File[broker servername config]/ensure: created
    
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-node-proxy]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Node/Service[openshift-port-proxy]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Node/Service[openshift-gears]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Node/Service[cgconfig]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Node/Service[openshift-cgroups]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Node/Service[cgred]/enable: enable changed 'false' to 'true'
    Notice: /Stage[main]/Openshift_origin::Node/Service[openshift-node-web-proxy]/enable: enable changed 'false' to 'true'
    Info: FileBucket adding {md5}104412fe157dff15f2bc90dae6785f9b
    
    Info: /File[node servername config]: Filebucketed /etc/httpd/conf.d/000001_openshift_origin_node_servername.conf to puppet with sum 104412fe157dff15f2bc90dae6785f9b
    
    Notice: /File[node servername config]/content: content changed '{md5}104412fe157dff15f2bc90dae6785f9b' to '{md5}2d19ff903cd436797948390f6a02db08'
    
    Notice: /Stage[main]/Openshift_origin::Broker/Package[bson_ext]/ensure: ensure changed '["1.6.4"]' to '1.8.2'
    Notice: /Stage[main]/Openshift_origin::Broker/Package[json]/ensure: ensure changed '["1.6.5"]' to '1.7.6'
    Notice: /Stage[main]/Openshift_origin::Broker/Package[mysql]/ensure: created
    Notice: /Stage[main]/Openshift_origin::Broker/Package[fakefs]/ensure: created
    Info: FileBucket got a duplicate file {md5}d797843b1ac6a9ce66ce63dd7c30ce7f
    
    Info: /File[openshift broker-dev.conf]: Filebucketed /etc/openshift/broker-dev.conf to puppet with sum d797843b1ac6a9ce66ce63dd7c30ce7f
    
    Notice: /File[openshift broker-dev.conf]/content: content changed '{md5}d797843b1ac6a9ce66ce63dd7c30ce7f' to '{md5}982bf6e2252385c3b7152bad463cbf8a'
    
    Notice: /File[openshift broker-dev.conf]/mode: mode changed '0640' to '0644'
    
    Notice: /Stage[main]/Openshift_origin::Broker/Package[rack]/ensure: ensure changed '["1.4.5", "1.4.0"]' to '1.4.4'
    Notice: /Stage[main]/Openshift_origin::Activemq/Package[activemq]/ensure: created
    Notice: /File[/var/run/activemq/]/mode: mode changed '0755' to '0750'
    Notice: /File[/etc/tmpfiles.d/activemq.conf]/ensure: defined content as '{md5}ec359db115f267c488e1e60f4b9394d1'
    Info: FileBucket adding {md5}9788a288c3de9a7e2f533004aadad4ea
    Info: /File[jetty-realm.properties config]: Filebucketed /etc/activemq/jetty-realm.properties to puppet with sum 9788a288c3de9a7e2f533004aadad4ea
    Notice: /File[jetty-realm.properties config]/content: content changed '{md5}9788a288c3de9a7e2f533004aadad4ea' to '{md5}55e794bdbdf825364bccdc6522069bd0'
    Notice: /File[jetty-realm.properties config]/mode: mode changed '0644' to '0444'
    Info: FileBucket adding {md5}90431cb5441156e9b009c17197f79f1f
    
    Info: /File[jetty.xml config]: Filebucketed /etc/activemq/jetty.xml to puppet with sum 90431cb5441156e9b009c17197f79f1f
    
    Notice: /File[jetty.xml config]/content: content changed '{md5}90431cb5441156e9b009c17197f79f1f' to '{md5}722e1366638ebb24935d6156edec4ddd'
    
    Notice: /File[jetty.xml config]/mode: mode changed '0644' to '0444'
    
    Info: FileBucket adding {md5}e92d428e990af9ecdc8326d4dda39a08
    
    Info: /File[activemq.xml config]: Filebucketed /etc/activemq/activemq.xml to puppet with sum e92d428e990af9ecdc8326d4dda39a08
    
    Notice: /File[activemq.xml config]/content: content changed '{md5}e92d428e990af9ecdc8326d4dda39a08' to '{md5}bb951fd0ed21dde482a8f222842778f1'
    
    Notice: /File[activemq.xml config]/mode: mode changed '0644' to '0444'
    
    Notice: /Stage[main]/Openshift_origin::Node/Package[openshift-origin-cartridge-10gen-mms-agent]/ensure: created
    Info: FileBucket adding {md5}b8b44b045259525e0fae9e38fdb2aeeb
    
    Info: /File[openshift node pam runuser]: Filebucketed /etc/pam.d/runuser to puppet with sum b8b44b045259525e0fae9e38fdb2aeeb
    Notice: /File[openshift node pam runuser]/content: content changed '{md5}b8b44b045259525e0fae9e38fdb2aeeb' to '{md5}8d732ec764cb6e2ad92f27451efe65d8'
    Notice: /Stage[main]/Openshift_origin::Broker/Package[parseconfig]/ensure: ensure changed '["1.0.2"]' to '0.5.2'
    Notice: Finished catalog run in 3313.82 seconds

## Creating an application on the VirtualBox VM

    Helios:origin_vagrant kraman$ vagrant ssh
    Last login: Sat Feb 16 23:36:49 2013
    [vagrant@broker ~]$ rhc setup
    OpenShift Client Tools (RHC) Setup Wizard
    
    This wizard will help you upload your SSH keys, set your application namespace, and check that other programs like Git are properly installed.
    
    The server's certificate is self-signed, which means that a secure connection can't be established to 'broker.example.com'.
    
    You may bypass this check, but any data you send to the server could be intercepted by others.
    
    Connect without checking the certificate? (yes|no): yes
    Login to broker.example.com: admin
    Password: *****
    
    Saving configuration to /home/vagrant/.openshift/express.conf ... done
    
    No SSH keys were found. We will generate a pair of keys for you.
    
        Created: /home/vagrant/.ssh/id_rsa.pub
    
    Your public SSH key must be uploaded to the OpenShift server to access code.  Upload now? (yes|no) yes
    
    Since you do not have any keys associated with your OpenShift account, your new key will be uploaded as the 'default' key.
    
      Type:        ssh-rsa
      Fingerprint: aa:04:c1:58:61:27:c2:f4:c7:49:cc:15:29:55:0a:6c
    
    Uploading key 'default' from /home/vagrant/.ssh/id_rsa.pub ... done
    
    Checking for git ... found git version 1.8.1.2
    
    Checking common problems .. done
    
    Checking your namespace ... none
    
    Your namespace is unique to your account and is the suffix of the public URLs we assign to your applications. You may configure your namespace here or leave it blank and use 'rhc domain create' to create a namespace later.  You will not be able to create applications
    without first creating a namespace.
    
    Please enter a namespace (letters and numbers only) |<none>|: localns
    Your domain name 'localns' has been successfully created
    
    Checking for applications ... none
    
    Run 'rhc app create' to create your first application.
    
      Do-It-Yourself                 rhc app create <app name> diy-0.1
      Jenkins Server 1               rhc app create <app name> jenkins-1
      Node.js 0.6                    rhc app create <app name> nodejs-0.6
      PHP 5.4                        rhc app create <app name> php-5.4
      Perl 5.16                      rhc app create <app name> perl-5.16
      Python 2.7 Community Cartridge rhc app create <app name> python-2.7
      Python 3.3 Community Cartridge rhc app create <app name> python-3.3
      Ruby 1.9                       rhc app create <app name> ruby-1.9
    
      You are using 0 of 100 total gears
      The following gear sizes are available to you: small
    
    Your client tools are now configured.
    [vagrant@broker ~]$ rhc app create testphp php-5.4
    Password: *****
    
    Application Options
    -------------------
      Namespace:  localns
      Cartridges: php-5.4
      Gear Size:  default
      Scaling:    no
    
    Creating application 'testphp' ... done
    
    Waiting for your DNS name to be available ... done
    
    Downloading the application Git repository ...
    Cloning into 'testphp'...
    The authenticity of host 'testphp-localns.example.com (127.0.0.1)' can't be established.
    RSA key fingerprint is fc:e1:a2:44:e5:99:64:bb:2c:69:93:0e:db:ba:e5:05.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added 'testphp-localns.example.com' (RSA) to the list of known hosts.
    
    Your application code is now in 'testphp'
    
    testphp @ http://testphp-localns.example.com/ (uuid: 512740296892dffca4000005)
    ------------------------------------------------------------------------------
      Created: 9:53 AM
      Gears:   1 (defaults to small)
      Git URL: ssh://512740296892dffca4000005@testphp-localns.example.com/~/git/testphp.git/
      SSH:     512740296892dffca4000005@testphp-localns.example.com
    
      php-5.4 (PHP 5.4)
      -----------------
        Gears: 1 small
    
    RESULT:
    Application testphp was created.
    
    [vagrant@broker ~]$ 

## Notes

1. If using Ubuntu 12.04, the init script is missing a flag in the tar command.

        curl -s https://nodeload.github.com/openshift/puppet-openshift_origin/legacy.tar.gz/master | tar zxf – –strip 1 –wildcards ‘**/test’ && mv test origin_vagrant