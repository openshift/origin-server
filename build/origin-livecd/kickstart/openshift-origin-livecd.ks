%include /usr/share/spin-kickstarts/fedora-live-base.ks

selinux --enforcing
firewall --enabled --service=mdns,ssh,dns,https
part / --size 6000  --fstype ext4 --ondisk sda
services --enabled=network,sshd --disabled=NetworkManager
xconfig --startxonboot
bootloader --append="biosdevname=0"

repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch --exclude=ruby,ruby-devel,ruby-irb,ruby-libs,ruby-rdoc,ruby-ri,ruby-static,ruby-tcltk
repo --name=fedora-ruby --baseurl=http://mirror.openshift.com/pub/fedora-ruby/$basearch/
repo --name=passenger --baseurl=http://passenger.stealthymonkeys.com/fedora/$releasever/$basearch
repo --name=openshift-origin --baseurl=http://mirror.openshift.com/pub/crankcase/fedora-$releasever/$basearch
repo --name=local-build --baseurl=file:///root/rpmbuild/RPMS

%packages
openshift-origin-livecd


%end

