Summary:        OpenShift Origin
Name:           openshift-origin
Version:        0.0.1
Release:        1%{?dist}
Group:          Development/System
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        openshift-origin-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

Requires: vim
Requires: git
Requires: ruby
Requires: rubygems
Requires: java-1.6.0-openjdk
Requires: jpackage-utils
Requires: java-1.6.0-openjdk-devel
Requires: emacs
Requires: tig
Requires: tig
Requires: stickshift-broker
Requires: rubygem-gearchanger-oddjob-plugin
Requires: rubygem-swingshift-mongo-plugin
Requires: rubygem-uplift-bind-plugin
Requires: rubygem-stickshift-node
Requires: rhc
Requires: openssh-server

BuildRequires: tito
BuildRequires: fedora-kickstarts
BuildRequires: livecd-tools
BuildRequires: wget
BuildArch:     noarch

%description
Installs the OpenShift Origin environment locally and provides a live-cd kickstart

%prep
%setup -q

%build

%post
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

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=dhcp
ONBOOT=yes
EOF

echo 'AcceptEnv GIT_SSH' >> /etc/ssh/sshd_config
ln -s /usr/bin/sssh /usr/bin/rhcsh

lokkit --service=ssh
lokkit --service=https
lokkit --service=dns

sed -i -e "s/^# Add plugin gems here/# Add plugin gems here\ngem 'swingshift-mongo-plugin'\n/" /var/www/stickshift/broker/Gemfile
echo "require File.expand_path('../plugin-config/swingshift-mongo-plugin.rb', __FILE__)" >> /var/www/stickshift/broker/config/environments/development.rb

sed -i -e "s/^# Add plugin gems here/# Add plugin gems here\ngem 'uplift-bind-plugin'\n/" /var/www/stickshift/broker/Gemfile
echo "require File.expand_path('../plugin-config/uplift-bind-plugin.rb', __FILE__)" >> /var/www/stickshift/broker/config/environments/development.rb

sed -i -e "s/^# Add plugin gems here/# Add plugin gems here\ngem 'gearchanger-oddjob-plugin'\n/" /var/www/stickshift/broker/Gemfile

cat <<EOF >> /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

pushd /var/www/stickshift/broker/ && bundle install && chown apache:apache Gemfile.lock && popd

chmod 755 /etc/rc.d/init.d/livesys-late-openshift
/sbin/restorecon /etc/rc.d/init.d/livesys-late-openshift

chkconfig --add livesys-late-openshift
chkconfig sshd on
chkconfig stickshift-broker on
chkconfig httpd on
chkconfig mongod on
chkconfig oddjobd on

%postun
rm -f /usr/bin/rhcsh

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}
mkdir -p %{buildroot}/etc/skel/.config/autostart
cp skel/*.desktop %{buildroot}/etc/skel/.config/autostart/
mkdir -p %{buildroot}/etc/skel/.openshift
cp config/express.conf %{buildroot}/etc/skel/.openshift/
cp doc/SOURCES.txt %{buildroot}/etc/skel/
mkdir -p %{buildroot}/etc/stickshift
cp config/resource_limits.conf %{buildroot}/etc/stickshift

mkdir -p %{buildroot}/var/www/html
cp doc/getting_started.html %{buildroot}/var/www/html

mkdir -p %{buildroot}/etc/rc.d/init.d
cp init-scripts/livesys-late-openshift %{buildroot}/etc/rc.d/init.d/

%clean
rm -rf %{buildroot}                                

%files
%defattr(-,root,root,-)
/etc/skel
%attr(0700,-,-) /etc/rc.d/init.d/livesys-late-openshift
%attr(0555,apache,apache) /var/www/html
%attr(0555,-,-)  /etc/stickshift/resource_limits.conf

%changelog

