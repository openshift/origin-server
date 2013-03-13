#!/bin/bash

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

load_resource_limits_conf

application="$1"
uuid="$2"
IP="$3"

setup_app_dir_vars
setup_user_vars

HAPROXY_DIR=`echo $APP_HOME/haproxy-1.4 | tr -s /`
[ -d "$HAPROXY_DIR" ]  ||   HAPROXY_DIR=`echo $APP_HOME/$application | tr -s /`

. $APP_HOME/.env/OPENSHIFT_INTERNAL_IP
. $APP_HOME/.env/OPENSHIFT_GEAR_UUID

cat <<EOF > "$HAPROXY_DIR/conf/haproxy.cfg.template"
#---------------------------------------------------------------------
# Example configuration for a possible web application.  See the
# full configuration options online.
#
#   http://haproxy.1wt.eu/download/1.4/doc/configuration.txt
#
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    # to have these messages end up in /var/log/haproxy.log you will
    # need to:
    #
    # 1) configure syslog to accept network log events.  This is done
    #    by adding the '-r' option to the SYSLOGD_OPTIONS in
    #    /etc/sysconfig/syslog
    #
    # 2) configure local2 events to go to the /var/log/haproxy.log
    #   file. A line like the following can be added to
    #   /etc/sysconfig/syslog
    #
    #    local2.*                       /var/log/haproxy.log
    #
    #log         127.0.0.1 local2

    pidfile     $HAPROXY_DIR/run/haproxy.pid
    maxconn     256
    daemon

    # turn on stats unix socket
    stats socket $HAPROXY_DIR/run/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    #option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 128

listen stats $IP2:8080
    mode http
    stats enable
    stats uri /

listen express $IP:8080
    cookie GEAR insert indirect nocache
    option httpchk GET /
    balance leastconn
    server  filler $IP2:8080 backup
    server  local-gear $OPENSHIFT_INTERNAL_IP:8080 maxconn 2 check fall 2 rise 3 inter 2000 cookie local-$OPENSHIFT_GEAR_UUID
EOF

cp $HAPROXY_DIR/conf/haproxy.cfg.template $HAPROXY_DIR/conf/haproxy.cfg
chown $uuid $HAPROXY_DIR/conf/haproxy.cfg
touch $HAPROXY_DIR/conf/haproxy.cfg.lock
chown $uuid $HAPROXY_DIR/conf/haproxy.cfg.lock

