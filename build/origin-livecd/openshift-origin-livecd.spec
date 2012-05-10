Summary:        OpenShift Origin Live CD
Name:           openshift-origin-livecd
Version:        0.0.2
Release:        1%{?dist}
Group:          Development/System
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        openshift-origin-livecd-%{version}.tar.gz
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
Requires: cartridge-10gen-mms-agent-0.1
Requires: cartridge-cron-1.4
Requires: cartridge-diy-0.1
Requires: cartridge-jbossas-7
Requires: cartridge-jenkins-1.4
Requires: cartridge-jenkins-client-1.4
Requires: cartridge-mongodb-2.0
Requires: cartridge-mysql-5.1
Requires: cartridge-nodejs-0.6
Requires: cartridge-perl-5.10
Requires: cartridge-php-5.3
Requires: cartridge-phpmyadmin-3.4
Requires: cartridge-python-2.6
Requires: cartridge-ruby-1.8
Requires: rhc

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

# Setup swap for VM
[ -f /.swap ] || ( /bin/dd if=/dev/zero of=/.swap bs=1024 count=1024000
    /sbin/mkswap -f /.swap
    /sbin/swapon /.swap
    echo "/.swap swap   swap    defaults        0 0" >> /etc/fstab
)

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

chkconfig sshd on
chkconfig stickshift-broker on
chkconfig httpd on
chkconfig mongod on
chkconfig oddjobd on

service sshd restart
service mongod restart
service httpd restart
service httpd restart

pushd /var/www/stickshift/broker/ && bundle install && chown apache:apache Gemfile.lock && popd

%postun
rm -f /usr/share/selinux/packages/rubygem-passenger/Gemfile.lock
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
* Thu May 10 2012 Krishna Raman <kraman@gmail.com> 0.0.2-1
- new package built with tito


