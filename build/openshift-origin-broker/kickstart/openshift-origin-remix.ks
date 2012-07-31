%include /usr/share/spin-kickstarts/fedora-live-desktop.ks

part / --size 7000
selinux --enforcing
firewall --enabled --service=mdns,ssh,dns,https
services --enabled=network,sshd
xconfig --startxonboot
bootloader --append="biosdevname=0"
network --bootproto=dhcp --device=eth0

repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch --exclude=ruby,ruby-devel,ruby-irb,ruby-libs,ruby-rdoc,ruby-ri,ruby-static,ruby-tcltk
repo --name=fedora-ruby --baseurl=http://mirror.openshift.com/pub/fedora-ruby/$basearch/
repo --name=openshift-origin --baseurl=http://mirror.openshift.com/pub/crankcase/fedora-$releasever/$basearch
repo --name=openshift --baseurl=https://openshift.redhat.com/app/repo/rpms/$releasever/$basearch
#ADDITIONAL REPOS

%packages
# rebranding
-fedora-logos
-fedora-release
-fedora-release-notes
generic-release
generic-logos
generic-release-notes
gcc


openshift-origin-broker
openshift-origin-node
cartridge-10gen-mms-agent-0.1
cartridge-cron-1.4
cartridge-diy-0.1
#cartridge-jbossas-7
#cartridge-jenkins-1.4
#cartridge-jenkins-client-1.4
cartridge-mongodb-2.0
cartridge-mysql-5.1
cartridge-nodejs-0.6
cartridge-perl-5.10
cartridge-php-5.3
cartridge-phpmyadmin-3.4
cartridge-python-2.6
cartridge-ruby-1.8
cartridge-haproxy-1.4
%end

%post
echo "OpenShift Origin Fedora Remix (build date:`/bin/date`)" > /etc/openshift-release
echo "Git revision: #GIT_REV#" >> /etc/openshift-release
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

export PATH=/usr/bin:/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/sbin:$PATH
cd /var/www/stickshift/broker
bundle install

echo "Static broker setup" >> /var/log/openshift-init-setup
/usr/bin/ss-setup-broker --livecd --static-dns 8.8.8.8,8.8.4.4 | tee -a /var/log/openshift-init-setup
echo "Runtime broker setup" >> /var/log/openshift-init-setup

cat <<EOF > /etc/skel/.config/autostart/xhost.desktop
[Desktop Entry]
Type=Application
Exec=/usr/bin/xhost +
Hidden=false
X-GNOME-Autostart-enabled=true
Name[en_US]=Xhost
Name=Xhost
Comment[en_US]=Xhost
Comment=Xhost
EOF

cat <<EOF > /usr/bin/launch_openshift_doc.sh
#/bin/sleep 30
/usr/bin/firefox file:///var/www/html/getting_started.html
EOF
chmod +x /usr/bin/launch_openshift_doc.sh

cat <<EOF > /usr/bin/complete_origin_setup
#!/usr/bin/ruby

system "service mongod start"
print "Initializing mongodb database..."
while not system('/bin/fgrep "[initandlisten] waiting for connections" /var/log/mongodb/mongodb.log') do
  print "."
  sleep 5
end

print "Setup mongo db user\n"
print \`/usr/bin/mongo localhost/stickshift_broker_dev --eval 'db.addUser("stickshift", "mooo")'\`

print "Register admin user\n"
print \`mongo stickshift_broker_dev --eval 'db.auth_user.update({"_id":"admin"}, {"_id":"admin","user":"admin","password":"2a8462d93a13e51387a5e607cbd1139f"}, true)'\`

ext_address = \`/sbin/ip addr show dev eth0 | awk '/inet / { split(\$2,a, "/") ; print a[1];}'\`
system "/usr/bin/ss-register-dns -h broker -n #{ext_address.strip}"
system "/usr/bin/ss-setup-node --with-node-hostname broker --with-broker-ip #{ext_address}"

system "service stickshift-broker restart"
system "/sbin/chkconfig livesys-late-openshift off"
EOF
chmod +x /usr/bin/complete_origin_setup

cat <<EOF > /etc/rc.d/init.d/livesys-late-openshift
#!/bin/bash
#
# live: Late init script for live image
#
# chkconfig: 345 99 01
# description: Late init script for configuring image

start() {
  /usr/bin/complete_origin_setup | tee -a /var/log/openshift-init-setup
}

case "\$1" in
  start)
	start
	;;
  stop)
	;;
esac

exit 0
EOF
/bin/chmod 0700 /etc/rc.d/init.d/livesys-late-openshift
/sbin/restorecon /etc/rc.d/init.d/livesys-late-openshift
/sbin/chkconfig --add livesys-late-openshift
/sbin/chkconfig livesys-late-openshift on
%end
