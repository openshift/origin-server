#!/bin/bash

# Exit on any errors
set -x
#set -xe

[ $# -eq 1 ] || { echo "Usage: $0 <li-repo-path>" ; exit 1; }
li_repo=$1

#Turn off SElinux
setenforce 0

# Get interface
IFS=" "
ifc=( $(ifconfig | grep "encap:Ethernet" | awk '{print $1;}' | tr '\n' ' ') )
unset IFS

# Turn off NetworkManager service
chkconfig NetworkManager off
service NetworkManager stop
chkconfig named on

# Kill dhclient
kill -9  `ps -aef | grep  dhclient | grep -v grep | awk '{print $2;}'` 2> /dev/null

# stop services
service named stop
service network stop

# copy files
mkdir -p /var/named/dynamic
pushd $li_repo/misc/devenv/var/named
cp example.com.db.init /tmp/dummy
sed 's/example/rhcloud/g' </tmp/dummy  >/var/named/rhcloud.com.db.init
cp example.com.key /tmp/dummy
sed 's/example/rhcloud/g' </tmp/dummy  >/var/named/rhcloud.com.key
cp dynamic/example.com.db /tmp/dummy
sed 's/example/rhcloud/g' </tmp/dummy  >/var/named/dynamic/rhcloud.com.db
#touch /var/named/dynamic/rhcloud.com.db.jnl
popd

pushd $li_repo/misc/devenv/etc
cp named.conf /tmp/dummy
sed 's/example/rhcloud/g' </tmp/dummy  >/etc/named.conf
mkdir -p /var/named/data
touch /var/named/data/named.run
touch /var/named/data/queries.log
touch /var/named/data/cache_dump.db
touch /var/named/data/named_stats.txt
touch /var/named/data/named_mem_stats.txt
#touch /var/named/managed-keys.bind
#touch /var/named/managed-keys.bind.jnl
touch /var/named/forwarders.conf
chmod 755 /var/named/forwarders.conf
cp /usr/share/doc/bind-*/sample/var/named/named* /var/named/
mkdir -p /etc/dhcp
for (( i=0; i < ${#ifc[@]}; i++ ))
do
  cp dhclient-eth0.conf /etc/dhclient-${ifc[$i]}.conf
  cp dhcp/dhclient-eth0-up-hooks /tmp/dummy
  sed s/eth0/${ifc[$i]}/g </tmp/dummy  >/etc/dhcp/dhclient-${ifc[$i]}-up-hooks
  chmod 755 /etc/dhcp/dhclient-${ifc[$i]}-up-hooks
done
cp rndc.conf /etc/rndc.conf
popd

#FIXME: temporary workaround 
sed /upstream_hints/d </etc/named.conf >/tmp/dummy
cp /tmp/dummy /etc/named.conf

chown -R named:named /var/named
rm /tmp/dummy

# start services
service named start
service network start
