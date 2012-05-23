%include /usr/share/spin-kickstarts/fedora-live-desktop.ks

part / --size 6000
selinux --enforcing
firewall --enabled --service=mdns,ssh,dns,https
services --enabled=network,sshd --disabled=NetworkManager
xconfig --startxonboot
bootloader --append="biosdevname=0"

repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch --exclude=ruby,ruby-devel,ruby-irb,ruby-libs,ruby-rdoc,ruby-ri,ruby-static,ruby-tcltk
repo --name=fedora-ruby --baseurl=http://mirror.openshift.com/pub/fedora-ruby/$basearch/
repo --name=passenger --baseurl=http://passenger.stealthymonkeys.com/fedora/$releasever/$basearch
repo --name=openshift-origin --baseurl=http://mirror.openshift.com/pub/crankcase/fedora-$releasever/$basearch
#ADDITIONAL REPOS

%packages
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

openshift-origin-broker
openshift-origin-node
%end

