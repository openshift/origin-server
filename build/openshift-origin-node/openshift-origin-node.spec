Summary:        OpenShift Origin Node
Name:           openshift-origin-node
Version:        0.0.3
Release:        1%{?dist}
Group:          Development/System
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        openshift-origin-node-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires:       vim
Requires:       nano
Requires:       emacs-nox
Requires:       git
Requires:       ruby
Requires:       rubygems
Requires:       java-1.6.0-openjdk
Requires:       jpackage-utils
Requires:       java-1.6.0-openjdk-devel
Requires:       openssh-server
Requires:       lsb

Requires:       rhc
Requires:       mcollective-qpid-plugin
Requires:       stickshift-mcollective-agent
Requires:       rubygem-stickshift-node
Requires:       stickshift-port-proxy

BuildArch:      noarch

%description
Installs the OpenShift Origin environment locally

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}/etc/systemd/system
mkdir -p %{buildroot}/var/run/stickshift

mv bin/oo-setup-node %{buildroot}%{_bindir}
mv bin/oo-admin-ctl-gears %{buildroot}%{_bindir}
mv services/stickshift-gears.service %{buildroot}/etc/systemd/system/stickshift-gears.service

%files
%defattr(-,root,root,-)
%attr(0700,-,-) /usr/bin/oo-setup-node
%attr(0700,-,-) /usr/bin/oo-admin-ctl-gears
/etc/systemd/system
/var/run/stickshift

%post
semanage -i - <<_EOF
boolean -m --on httpd_can_network_connect
boolean -m --on httpd_can_network_relay
boolean -m --on httpd_read_user_content
boolean -m --on httpd_enable_homedirs
_EOF
semodule -i /usr/share/selinux/packages/rubygem-stickshift-common/stickshift.pp -d passenger -i /usr/share/selinux/packages/rubygem-passenger/rubygem-passenger.pp
/sbin/fixfiles -R rubygem-passenger restore
/sbin/fixfiles -R mod_passenger restore
/sbin/restorecon -R -v /var/run
/sbin/restorecon -rv /usr/lib/ruby/gems/1.8/gems/passenger-*
/sbin/restorecon -r /var/lib/stickshift /etc/stickshift/stickshift-node.conf /etc/httpd/conf.d/stickshift
/sbin/restorecon -r /usr/sbin/mcollectived /var/log/mcollective.log /run/mcollective.pid

# Increase kernel semaphores to accomodate many httpds
echo "kernel.sem = 250  32000 32  4096" >> /etc/sysctl.conf
sysctl kernel.sem="250  32000 32  4096"

# Move ephemeral port range to accommodate app proxies
echo "net.ipv4.ip_local_port_range = 15000 35530" >> /etc/sysctl.conf
sysctl net.ipv4.ip_local_port_range="15000 35530"

# Increase the connection tracking table size
echo "net.netfilter.nf_conntrack_max = 1048576" >> /etc/sysctl.conf
sysctl net.netfilter.nf_conntrack_max=1048576

# Increase max SSH connections and tries to 40
perl -p -i -e "s/^#MaxSessions .*$/MaxSessions 40/" /etc/ssh/sshd_config
perl -p -i -e "s/^#MaxStartups .*$/MaxStartups 40/" /etc/ssh/sshd_config
perl -p -i -e "s/^#auth = .*$/auth = true/" /etc/mongodb.conf

echo 'AcceptEnv GIT_SSH' >> /etc/ssh/sshd_config
ln -s /usr/bin/sssh /usr/bin/rhcsh

lokkit --service=ssh
lokkit --service=https
lokkit --service=http
lokkit --port=35531-65535:tcp

cat <<EOF > /etc/mcollective/client.cfg
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
libdir = /usr/libexec/mcollective
loglevel = debug
logfile = /var/log/mcollective-client.log

# Plugins
securityprovider = psk
plugin.psk = unset
connector = qpid
plugin.qpid.host=broker.example.com
plugin.qpid.secure=false
plugin.qpid.timeout=5

# Facts
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml
EOF

cat <<EOF > /etc/mcollective/server.cfg
topicprefix = /topic/
main_collective = mcollective
collectives = mcollective
libdir = /usr/libexec/mcollective
logfile = /var/log/mcollective.log
loglevel = debug
daemonize = 1 
direct_addressing = n

# Plugins
securityprovider = psk
plugin.psk = unset
connector = qpid
plugin.qpid.host=broker.example.com
plugin.qpid.secure=false
plugin.qpid.timeout=5

# Facts
factsource = yaml
plugin.yaml = /etc/mcollective/facts.yaml
EOF

if [ ! -f /etc/qpidd.conf.orig ] ; then
  mv /etc/qpidd.conf /etc/qpidd.conf.orig
fi
cp -f /etc/qpidd.conf.orig /etc/qpidd.conf
if [[ "x`fgrep auth= /etc/qpidd.conf`" == xauth* ]] ; then
  sed -i -e 's/auth=yes/auth=no/' /etc/qpidd.conf
else
  echo "auth=no" >> /etc/qpidd.conf   
fi

chkconfig sshd on
chkconfig httpd on
chkconfig qpidd on
chkconfig mcollective on
chkconfig network on

%postun

semanage -i - <<_EOF
boolean -m --off httpd_can_network_connect
boolean -m --off httpd_can_network_relay
boolean -m --off httpd_read_user_content
boolean -m --off httpd_enable_homedirs
_EOF
semodule -r stickshift

%clean
rm -rf %{buildroot}                                

%changelog
* Tue Aug 21 2012 Brenton Leanhardt <bleanhar@redhat.com> 0.0.3-1
- remove dhcp assumption from %%post and leave that to scripts
  (lmeyer@redhat.com)
- adding not-origin tag to postgres cucumber feature and specifying complete
  path for ip program (abhgupta@redhat.com)
- Removing gateway config for internal device since it causes default route to
  be setup incorrectly (kraman@gmail.com)
- Merge pull request #317 from CodeBlock/patch-2 (kraman@gmail.com)
- Add nano and emacs-nox to openshift-origin-node (ricky@elrod.me)
- setup broker/nod script fixes for static IP and custom ethernet devices add
  support for configuring different domain suffix (other than example.com)
  Fixing dependency to qpid library (causes fedora package conflict) Make
  livecd start faster by doing static configuration during cd build rather than
  startup Fixes some selinux policy errors which prevented scaled apps from
  starting (kraman@gmail.com)
- Restart network on node during setup (kraman@gmail.com)
- Merge pull request #294 from kraman/dev/kraman/features/origin
  (kraman@gmail.com)
- OSS build fixes (kraman@gmail.com)
- Fix for BZ841681. (mpatel@redhat.com)
- Removing requirement to disable NetworkManager so that liveinst works Adding
  initial support for dual interfaces Adding "xhost +" so that liveinst can
  continue to work after hostname change to broker.example.com Added delay
  befor launching firefox so that network is stable Added rndc key generation
  for Bind Dns plugin instead of hardcoding it (kraman@gmail.com)
- Bugz# 834547. Added gear management commands to start/stop all gears on the
  node (kraman@gmail.com)

* Thu Jul 05 2012 Krishna Raman <kraman@gmail.com> 0.0.2-1
- MCollective updates - Added mcollective-qpid plugin - Added mcollective-
  gearchanger plugin - Added mcollective agent and facter plugins - Added
  option to support ignoring node profile - Added systemu dependency for
  mcollective-client (kraman@gmail.com)

* Fri Jun 29 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

