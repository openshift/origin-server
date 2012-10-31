%include /usr/share/spin-kickstarts/fedora-live-desktop.ks

part / --size 9000
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
git 
vim 
rubygem-thor 
rubygem-parseconfig 
tito 
make 
rubygem-aws-sdk 
tig 
mlocate 
bash-completion

openshift-origin-broker
rubygem-openshift-origin-node
openshift-origin-broker-util
openshift-origin-node-util
mcollective-qpid-plugin
rubygem-openshift-origin-auth-mongo
rubygem-openshift-origin-dns-bind
rubygem-openshift-origin-msg-broker-mcollective
openshift-origin-msg-node-mcollective
pam_openshift
openshift-origin-port-proxy
rhc

openshift-origin-cartridge-10gen-mms-agent-0.1
openshift-origin-cartridge-cron-1.4
openshift-origin-cartridge-diy-0.1
openshift-origin-cartridge-mongodb-2.2
openshift-origin-cartridge-mysql-5.1
openshift-origin-cartridge-nodejs-0.6
openshift-origin-cartridge-perl-5.10
openshift-origin-cartridge-php-5.3
openshift-origin-cartridge-phpmyadmin-3.4
openshift-origin-cartridge-python-2.6
openshift-origin-cartridge-ruby-1.8
openshift-origin-cartridge-haproxy-1.4
#openshift-origin-cartridge-jbossas-7
#openshift-origin-cartridge-jenkins-1.4
#openshift-origin-cartridge-jenkins-client-1.4
%end

%post
mknod /dev/loop0 b 7 0
mknod /dev/loop1 b 7 1
mknod /dev/loop2 b 7 2
mknod /dev/loop3 b 7 3
mknod /dev/loop4 b 7 4
mknod /dev/loop5 b 7 5
mknod /dev/loop6 b 7 6
mknod /dev/loop7 b 7 7

echo "OpenShift Origin Fedora Remix (build date:`/bin/date`)" > /etc/openshift-release
echo "Git revision: #GIT_REV#" >> /etc/openshift-release
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

echo "Static broker setup" >> /var/log/openshift-init-setup
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
/usr/bin/oo-setup-broker --static-dns 8.8.8.8,8.8.4.4 --debug | tee -a /var/log/openshift-init-setup
echo "Runtime broker setup" >> /var/log/openshift-init-setup
/usr/bin/updatedb

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes

BOOTPROTO=dhcp
DNS1=127.0.0.1
DNS2=8.8.8.8
DNS3=8.8.4.4
TYPE=Ethernet
DEFROUTE=yes
PEERROUTES=yes
EOF


mkdir -p /etc/skel/.config/autostart
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
/usr/bin/firefox file:///var/www/html/getting_started.html
EOF
chmod +x /usr/bin/launch_openshift_doc.sh

cat <<EOF > /usr/bin/complete-origin-setup
#!/usr/bin/ruby

ext_address = \`/sbin/ip addr show dev eth0 | awk '/inet / { split(\$2,a, "/") ; print a[1];}'\`
system "/usr/bin/oo-register-dns -h broker -n #{ext_address.strip}"
system "/sbin/chkconfig livesys-late-openshift off"
EOF
chmod a+rx /usr/bin/complete-origin-setup

cat <<EOF > /etc/rc.d/init.d/livesys-late-openshift
#!/bin/bash
#
# live: Init script for live image
#
# chkconfig: 345 99 01
# description: init script for configuring image

start() {
  /usr/bin/complete-origin-setup
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
