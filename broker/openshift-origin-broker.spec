%global htmldir %{_var}/www/html
%global brokerdir %{_var}/www/openshift/broker
%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}

%if 0%{?fedora} >= 16 || 0%{?rhel} >= 7
%global with_systemd 1
%global gemdir /usr/share/rubygems/gems
%else
%global with_systemd 0
%global gemdir /opt/rh/ruby193/root/usr/share/gems/gems
%endif

Summary:       OpenShift Origin broker components
Name:          openshift-origin-broker
Version:       1.15.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      httpd
# TODO: We need to audit these requirements.  Some of these are likely not hard
# requirements.
Requires:      mod_ssl
Requires:      %{?scl:%scl_prefix}mod_passenger
%if 0%{?scl:1}
Requires:      %{?scl:%scl_prefix}ruby-wrapper
Requires:      openshift-origin-util-scl
%else
Requires:      openshift-origin-util
%endif
Requires:      policycoreutils-python
Requires:      rubygem-openshift-origin-controller
Requires:      %{?scl:%scl_prefix}mod_passenger
Requires:      %{?scl:%scl_prefix}rubygem-bson_ext
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      %{?scl:%scl_prefix}rubygem-json_pure
# This gem is required by oo-admin-chk, oo-admin-fix-sshkeys, and
# oo-stats, for OpenShift::DataStore API support
Requires:      %{?scl:%scl_prefix}rubygem-mongo
Requires:      %{?scl:%scl_prefix}rubygem-mongoid
Requires:      %{?scl:%scl_prefix}rubygem-open4
Requires:      %{?scl:%scl_prefix}rubygem-parseconfig
Requires:      %{?scl:%scl_prefix}rubygem-passenger
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-regin
Requires:      %{?scl:%scl_prefix}rubygem-rest-client
Requires:      %{?scl:%scl_prefix}rubygem-systemu
Requires:      %{?scl:%scl_prefix}rubygem-xml-simple

Requires:      %{?scl:%scl_prefix}rubygem-actionmailer
Requires:      %{?scl:%scl_prefix}rubygem-actionpack
Requires:      %{?scl:%scl_prefix}rubygem-activemodel
Requires:      %{?scl:%scl_prefix}rubygem-activerecord
Requires:      %{?scl:%scl_prefix}rubygem-activeresource
Requires:      %{?scl:%scl_prefix}rubygem-activesupport
Requires:      %{?scl:%scl_prefix}rubygem-arel
Requires:      %{?scl:%scl_prefix}rubygem-bigdecimal
Requires:      %{?scl:%scl_prefix}rubygem-bson
Requires:      %{?scl:%scl_prefix}rubygem-builder
Requires:      %{?scl:%scl_prefix}rubygem-bundler
Requires:      %{?scl:%scl_prefix}rubygem-diff-lcs
Requires:      %{?scl:%scl_prefix}rubygem-dnsruby
Requires:      %{?scl:%scl_prefix}rubygem-erubis
Requires:      %{?scl:%scl_prefix}rubygem-hike
Requires:      %{?scl:%scl_prefix}rubygem-i18n
Requires:      %{?scl:%scl_prefix}rubygem-journey
Requires:      %{?scl:%scl_prefix}rubygem-json
Requires:      %{?scl:%scl_prefix}rubygem-mail
Requires:      %{?scl:%scl_prefix}rubygem-metaclass
Requires:      %{?scl:%scl_prefix}rubygem-mime-types
Requires:      %{?scl:%scl_prefix}rubygem-moped
Requires:      %{?scl:%scl_prefix}rubygem-multi_json
Requires:      %{?scl:%scl_prefix}rubygem-origin
Requires:      %{?scl:%scl_prefix}rubygem-polyglot
Requires:      %{?scl:%scl_prefix}rubygem-rack
Requires:      %{?scl:%scl_prefix}rubygem-rack-cache
Requires:      %{?scl:%scl_prefix}rubygem-rack-ssl
Requires:      %{?scl:%scl_prefix}rubygem-rack-test
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-railties
Requires:      %{?scl:%scl_prefix}rubygem-rdoc
Requires:      %{?scl:%scl_prefix}rubygem-regin
Requires:      %{?scl:%scl_prefix}rubygem-sprockets
Requires:      %{?scl:%scl_prefix}rubygem-state_machine
Requires:      %{?scl:%scl_prefix}rubygem-stomp
Requires:      %{?scl:%scl_prefix}rubygem-systemu
Requires:      %{?scl:%scl_prefix}rubygem-term-ansicolor
Requires:      %{?scl:%scl_prefix}rubygem-thor
Requires:      %{?scl:%scl_prefix}rubygem-tilt
Requires:      %{?scl:%scl_prefix}rubygem-treetop
Requires:      %{?scl:%scl_prefix}rubygem-tzinfo
Requires:      %{?scl:%scl_prefix}rubygem-xml-simple
Requires:      %{?scl:%scl_prefix}rubygem-syslog-logger

%if %{with_systemd}
Requires:      systemd-units
BuildRequires: systemd-units
%endif
BuildArch:     noarch
Provides:      openshift-broker

%description
This contains the broker 'controlling' components of OpenShift Origin.
This includes the public APIs for the client tools.

%prep
%setup -q

%build

%install
%if %{with_systemd}
mkdir -p %{buildroot}%{_unitdir}
%else
mkdir -p %{buildroot}%{_initddir}
%endif
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{htmldir}
mkdir -p %{buildroot}%{brokerdir}
mkdir -p %{buildroot}%{brokerdir}/httpd/root
mkdir -p %{buildroot}%{brokerdir}/httpd/run
mkdir -p %{buildroot}%{brokerdir}/httpd/conf
mkdir -p %{buildroot}%{brokerdir}/httpd/conf.d
mkdir -p %{buildroot}%{brokerdir}/run
mkdir -p %{buildroot}%{brokerdir}/tmp/cache
mkdir -p %{buildroot}%{brokerdir}/tmp/pids
mkdir -p %{buildroot}%{brokerdir}/tmp/sessions
mkdir -p %{buildroot}%{brokerdir}/tmp/sockets
mkdir -p %{buildroot}%{_sysconfdir}/httpd/conf.d
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig
mkdir -p %{buildroot}%{_sysconfdir}/openshift
mkdir -p %{buildroot}%{_sysconfdir}/openshift/plugins.d

cp -r . %{buildroot}%{brokerdir}
%if %{with_systemd}
mv %{buildroot}%{brokerdir}/systemd/openshift-broker.service %{buildroot}%{_unitdir}
mv %{buildroot}%{brokerdir}/systemd/openshift-broker.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-broker
%else
mv %{buildroot}%{brokerdir}/init.d/* %{buildroot}%{_initddir}
%endif
ln -s %{brokerdir}/public %{buildroot}%{htmldir}/broker
ln -s %{brokerdir}/public %{buildroot}%{brokerdir}/httpd/root/broker
ln -sf %{_libdir}/httpd/modules %{buildroot}%{brokerdir}/httpd/modules
ln -sf /etc/httpd/conf/magic %{buildroot}%{brokerdir}/httpd/conf/magic
mv %{buildroot}%{brokerdir}/httpd/000002_openshift_origin_broker_proxy.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/
mv %{buildroot}%{brokerdir}/httpd/000002_openshift_origin_broker_servername.conf %{buildroot}%{_sysconfdir}/httpd/conf.d/

mkdir -p %{buildroot}%{_var}/log/openshift/broker/httpd
touch %{buildroot}%{_var}/log/openshift/broker/user_action.log
touch %{buildroot}%{_var}/log/openshift/broker/production.log
touch %{buildroot}%{_var}/log/openshift/broker/development.log
touch %{buildroot}%{_var}/log/openshift/broker/usage.log

cp conf/broker.conf %{buildroot}%{_sysconfdir}/openshift/broker.conf
cp conf/broker.conf %{buildroot}%{_sysconfdir}/openshift/broker-dev.conf
cp conf/quickstarts.json %{buildroot}%{_sysconfdir}/openshift/quickstarts.json
cp conf/plugins.d/README %{buildroot}%{_sysconfdir}/openshift/plugins.d/README

# BZ986300
rm -f %{buildroot}%{brokerdir}/COPYRIGHT
rm -f %{buildroot}%{brokerdir}/.gitignore
rm -f %{buildroot}%{brokerdir}/LICENSE
rm -f %{buildroot}%{brokerdir}/openshift-origin-broker.spec
rm -f %{buildroot}%{brokerdir}/tmp/cache/.gitkeep
rm -rf %{buildroot}%{brokerdir}/conf
rm -rf %{buildroot}%{brokerdir}/doc
rm -rf %{buildroot}%{brokerdir}/init.d
rm -rf %{buildroot}%{brokerdir}/lib
rm -rf %{buildroot}%{brokerdir}/test

%if 0%{?fedora} >= 18
mv %{buildroot}%{brokerdir}/httpd/httpd.conf.apache-2.4 %{buildroot}%{brokerdir}/httpd/httpd.conf
%else
mv %{buildroot}%{brokerdir}/httpd/httpd.conf.apache-2.3 %{buildroot}%{brokerdir}/httpd/httpd.conf
%endif
rm %{buildroot}%{brokerdir}/httpd/httpd.conf.apache-*

%if 0%{?scl:1}
rm %{buildroot}%{brokerdir}/httpd/broker.conf
mv %{buildroot}%{brokerdir}/httpd/broker-scl-ruby193.conf %{buildroot}%{brokerdir}/httpd/broker.conf
%else
rm %{buildroot}%{brokerdir}/httpd/broker-scl-ruby193.conf
%endif

# Remove dependencies not needed at runtime
sed -i -e '/NON-RUNTIME BEGIN/,/NON-RUNTIME END/d' %{buildroot}%{brokerdir}/Gemfile

%files
%doc LICENSE COPYRIGHT
%defattr(0640,apache,apache,0750)
%attr(0750,-,-) %{_var}/log/openshift/broker
%attr(0750,-,-) %{_var}/log/openshift/broker/httpd
%attr(0750,-,-) %{brokerdir}/script
%attr(0750,-,-) %{brokerdir}/tmp
%attr(0750,-,-) %{brokerdir}/tmp/cache
%attr(0750,-,-) %{brokerdir}/tmp/pids
%attr(0750,-,-) %{brokerdir}/tmp/sessions
%attr(0750,-,-) %{brokerdir}/tmp/sockets
%dir %attr(0750,-,-) %{brokerdir}/httpd/conf.d
%{brokerdir}
%{htmldir}/broker
%config %{brokerdir}/config/environments/production.rb
%config %{brokerdir}/config/environments/development.rb
%config(noreplace) %{_sysconfdir}/httpd/conf.d/000002_openshift_origin_broker_proxy.conf
%config(noreplace) %{_sysconfdir}/httpd/conf.d/000002_openshift_origin_broker_servername.conf
%config(noreplace) %{_sysconfdir}/openshift/broker.conf
%config(noreplace) %{_sysconfdir}/openshift/broker-dev.conf
%doc %{_sysconfdir}/openshift/plugins.d/README
%dir %{_sysconfdir}/openshift/plugins.d
%config(noreplace) %{_sysconfdir}/openshift/quickstarts.json
%{_sysconfdir}/openshift/broker-dev.conf

%defattr(0640,root,root,0750)
%if %{with_systemd}
%{_unitdir}/openshift-broker.service
%attr(0644,-,-) %{_unitdir}/openshift-broker.service
%{_sysconfdir}/sysconfig/openshift-broker
%attr(0644,-,-) %{_sysconfdir}/sysconfig/openshift-broker
%else
%{_initddir}/openshift-broker
%attr(0750,-,-) %{_initddir}/openshift-broker
%endif


%post
%if %{with_systemd}
systemctl --system daemon-reload
# if under sysv, hopefully we don't need to reload anything
%endif

# We are forced to create these log files if they don't exist because we have
# command line tools that will load the Rails environment and create the logs
# as root.  We need the files labeled %ghost because we don't want these log
# files overwritten on RPM upgrade.
for l in %{_var}/log/openshift/broker/{development,production,user_action}.log; do
  if [ ! -f $l ]; then
    touch $l
  fi
  chown apache:apache $l
  chmod 640 $l
done

#selinux updated
semanage -i - <<_EOF
boolean -m --on httpd_can_network_connect
boolean -m --on httpd_can_network_relay
boolean -m --on httpd_read_user_content
boolean -m --on httpd_enable_homedirs
fcontext -a -t httpd_var_run_t '%{brokerdir}/httpd/run(/.*)?'
fcontext -a -t httpd_tmp_t '%{brokerdir}/tmp(/.*)?'
fcontext -a -t httpd_log_t '%{_var}/log/openshift/broker(/.*)?'
_EOF

chcon -R -t httpd_log_t %{_var}/log/openshift/broker
chcon -R -t httpd_tmp_t %{brokerdir}/httpd/run
chcon -R -t httpd_var_run_t %{brokerdir}/httpd/run
/sbin/fixfiles -R %{?scl:%scl_prefix}rubygem-passenger restore
/sbin/fixfiles -R %{?scl:%scl_prefix}mod_passenger restore
/sbin/restorecon -R -v /var/run
#/sbin/restorecon -rv %{_datarootdir}/rubygems/gems/passenger-*
/sbin/restorecon -rv %{brokerdir}/tmp
/sbin/restorecon -v '%{_var}/log/openshift/broker/user_action.log'

%postun
/sbin/fixfiles -R %{?scl:%scl_prefix}rubygem-passenger restore
/sbin/fixfiles -R %{?scl:%scl_prefix}mod_passenger restore
/sbin/restorecon -R -v /var/run

%changelog
* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Fixing test case to allow multiple domains before checking for duplicate
  namespace (kraman@gmail.com)
