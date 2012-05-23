Summary:        OpenShift Origin Broker
Name:           openshift-origin-broker
Version:        0.0.0
Release:        1%{?dist}
Group:          Development/System
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        openshift-origin-broker-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires: vim
Requires: git
Requires: ruby
Requires: rubygems
Requires: emacs
Requires: tig
Requires: openssh-server

Requires: stickshift-broker
Requires: rubygem-swingshift-mongo-plugin
Requires: rubygem-uplift-bind-plugin
Requires: rubygem-gearchanger-mcollective-plugin
Requires: mcollective-qpid-plugin
Requires: rhc

BuildRequires: tito
BuildRequires: fedora-kickstarts
BuildRequires: livecd-tools
BuildRequires: wget
BuildArch:     noarch

%description
Installs and configures a OpenShift Origin broker environment locally

%prep
%setup -q

%build

%post
perl -p -i -e "s/^#auth = .*$/auth = true/" /etc/mongodb.conf

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
NM_MANAGED=no
EOF

echo 'AcceptEnv GIT_SSH' >> /etc/ssh/sshd_config

lokkit --service=ssh
lokkit --service=https
lokkit --service=http
lokkit --service=dns

sed -i -e "s/^# Add plugin gems here/# Add plugin gems here\ngem 'swingshift-mongo-plugin'\n/" /var/www/stickshift/broker/Gemfile
echo "require File.expand_path('../plugin-config/swingshift-mongo-plugin.rb', __FILE__)" >> /var/www/stickshift/broker/config/environments/development.rb

sed -i -e "s/^# Add plugin gems here/# Add plugin gems here\ngem 'uplift-bind-plugin'\n/" /var/www/stickshift/broker/Gemfile
echo "require File.expand_path('../plugin-config/uplift-bind-plugin.rb', __FILE__)" >> /var/www/stickshift/broker/config/environments/development.rb

sed -i -e "s/^# Add plugin gems here/# Add plugin gems here\ngem 'gearchanger-mcollective-plugin'\n/" /var/www/stickshift/broker/Gemfile
echo "require File.expand_path('../plugin-config/gearchanger-mcollective-plugin.rb', __FILE__)" >> /var/www/stickshift/broker/config/environments/development.rb

pushd /var/www/stickshift/broker/ && bundle install && chown apache:apache Gemfile.lock && popd

cat <<EOF > /etc/resolv.conf
search example.com
nameserver 127.0.0.1
EOF

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

chmod 755 /etc/rc.d/init.d/livesys-late-openshift
/sbin/restorecon /etc/rc.d/init.d/livesys-late-openshift
/sbin/restorecon -r /usr/sbin/mcollectived /var/log/mcollective.log /run/mcollective.pid

if [ ! -f /etc/qpidd.conf.orig ] ; then
  mv /etc/qpidd.conf /etc/qpidd.conf.orig
fi
cp -f /etc/qpidd.conf.orig /etc/qpidd.conf
echo "auth=no" >> /etc/qpidd.conf

chkconfig --add livesys-late-openshift
chkconfig sshd on
chkconfig stickshift-broker on
chkconfig httpd on
chkconfig mongod on
chkconfig qpidd on
chkconfig mcollective on

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
mkdir -p %{buildroot}/etc/skel/.config/autostart
mkdir -p %{buildroot}%{_bindir}

cp skel/*.desktop %{buildroot}/etc/skel/.config/autostart/
mkdir -p %{buildroot}/etc/skel/.openshift
cp config/express.conf %{buildroot}/etc/skel/.openshift/
cp doc/SOURCES.txt %{buildroot}/etc/skel/
mkdir -p %{buildroot}/etc/stickshift

mkdir -p %{buildroot}/var/www/html
cp doc/getting_started.html %{buildroot}/var/www/html

mkdir -p %{buildroot}/etc/rc.d/init.d
cp init-scripts/livesys-late-openshift %{buildroot}/etc/rc.d/init.d/

mv bin/ss-register-dns %{buildroot}%{_bindir}
%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
/etc/skel
%attr(0700,-,-) /etc/rc.d/init.d/livesys-late-openshift
%attr(0555,apache,apache) /var/www/html
%attr(0700,-,-) /usr/bin/ss-register-dns

%changelog
* Fri May 25 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

* Fri May 25 2012 Krishna Raman <kraman@gmail.com> 0.0.1-1
- new package built with tito

* Wed May 16 2012 Krishna Raman <kraman@gmail.com> 0.0.2-1
- new package built with tito


