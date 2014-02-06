%global htmldir %{_var}/www/html
%global openshiftconfigdir %{_var}/www/.openshift
%global consoledir %{_var}/www/openshift/console
%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
    %global with_systemd 0
    %global gemdir /opt/rh/ruby193/root/usr/share/gems/gems
%else
    %global with_systemd 1
    %global gemdir /usr/share/rubygems/gems
%endif
%{!?scl:%global pkg_name %{name}}
%global rubyabi 1.9.1

Summary:       The OpenShift Management Console
Name:          openshift-origin-console
Version:       1.15.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem-openshift-origin-console
Requires:      %{?scl:%scl_prefix}rubygem-passenger
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native
Requires:      %{?scl:%scl_prefix}rubygem-passenger-native-libs
Requires:      %{?scl:%scl_prefix}mod_passenger

%if 0%{?scl:1}
Requires:      %{?scl:%scl_prefix}ruby-wrapper
Requires:      %{?scl:%scl_prefix}rubygem-therubyracer
Requires:      openshift-origin-util-scl
%endif
Requires:      %{?scl:%scl_prefix}rubygem-rails
Requires:      %{?scl:%scl_prefix}rubygem-compass-rails
Requires:      %{?scl:%scl_prefix}rubygem-sprockets
Requires:      %{?scl:%scl_prefix}rubygem-rdiscount
Requires:      %{?scl:%scl_prefix}rubygem-formtastic
Requires:      %{?scl:%scl_prefix}rubygem-net-http-persistent
Requires:      %{?scl:%scl_prefix}rubygem-haml
Requires:      %{?scl:%scl_prefix}rubygem-therubyracer
Requires:      %{?scl:%scl_prefix}rubygems-devel
Requires:      %{?scl:%scl_prefix}rubygem-coffee-rails
Requires:      %{?scl:%scl_prefix}rubygem-jquery-rails
Requires:      %{?scl:%scl_prefix}rubygem-uglifier

%if 0%{?fedora}
Requires:      openshift-origin-util
Requires:      v8-devel
Requires:      gcc-c++
%endif

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires:  ruby193-build
BuildRequires:  scl-utils-build
%endif
BuildRequires: %{?scl:%scl_prefix}rubygem-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-compass-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-sprockets
BuildRequires: %{?scl:%scl_prefix}rubygem-rdiscount
BuildRequires: %{?scl:%scl_prefix}rubygem-formtastic
BuildRequires: %{?scl:%scl_prefix}rubygem-net-http-persistent
BuildRequires: %{?scl:%scl_prefix}rubygem-haml
BuildRequires: %{?scl:%scl_prefix}rubygem-therubyracer
# Required by activesupport during the asset precompilation process
BuildRequires: %{?scl:%scl_prefix}rubygem-minitest
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildRequires: %{?scl:%scl_prefix}rubygem-coffee-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-jquery-rails
BuildRequires: %{?scl:%scl_prefix}rubygem-uglifier

%if 0%{?fedora} >= 19
BuildRequires: systemd
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: rubygem-openshift-origin-console

BuildArch:     noarch
Provides:      openshift-origin-console = %{version}
Obsoletes:     openshift-console

%description
This contains the console configuration components of OpenShift.
This includes the configuration necessary to run the console with mod_passenger.

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}

set -e
# Remove dependencies not needed at runtime
sed -i -e '/NON-RUNTIME BEGIN/,/NON-RUNTIME END/d' Gemfile

%if 0%{?fedora}%{?rhel} <= 6
rm -f Gemfile.lock
bundle install --local

mkdir -p %{buildroot}%{_var}/log/openshift/console/
mkdir -p -m 770 %{buildroot}%{_var}/log/openshift/console/httpd/
touch %{buildroot}%{_var}/log/openshift/console/production.log
chmod 0666 %{buildroot}%{_var}/log/openshift/console/production.log

CONSOLE_CONFIG_FILE=etc/openshift/console.conf \
  RAILS_ENV=production \
  RAILS_LOG_PATH=%{buildroot}%{_var}/log/openshift/console/production.log \
  RAILS_RELATIVE_URL_ROOT=/console bundle exec rake assets:precompile assets:public_pages

rm -rf tmp/cache/*
echo > %{buildroot}%{_var}/log/openshift/console/production.log

find . -name .gitignore -delete
find . -name .gitkeep -delete

rm -rf %{buildroot}%{_var}/log/openshift/*
rm -f Gemfile.lock
%endif
%{?scl:EOF}


%install
%if %{with_systemd}
mkdir -p %{buildroot}%{_unitdir}
%else
mkdir -p %{buildroot}%{_initddir}
%endif
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{openshiftconfigdir}
mkdir -p %{buildroot}%{htmldir}
mkdir -p %{buildroot}%{consoledir}
mkdir -p %{buildroot}%{consoledir}/httpd/root
mkdir -p %{buildroot}%{consoledir}/httpd/run
mkdir -p %{buildroot}%{consoledir}/httpd/conf
mkdir -p %{buildroot}%{consoledir}/httpd/conf.d
mkdir -p %{buildroot}%{consoledir}/tmp
mkdir -p %{buildroot}%{consoledir}/tmp/cache
mkdir -p %{buildroot}%{consoledir}/tmp/pids
mkdir -p %{buildroot}%{consoledir}/tmp/sessions
mkdir -p %{buildroot}%{consoledir}/tmp/sockets
mkdir -p %{buildroot}%{consoledir}/run
mkdir -p %{buildroot}%{_sysconfdir}/sysconfig
mkdir -p %{buildroot}%{_sysconfdir}/openshift
mkdir -p %{buildroot}%{_var}/log/openshift/console/httpd

cp -r . %{buildroot}%{consoledir}
%if %{with_systemd}
mv %{buildroot}%{consoledir}/systemd/openshift-console.service %{buildroot}%{_unitdir}
mv %{buildroot}%{consoledir}/systemd/openshift-console.env %{buildroot}%{_sysconfdir}/sysconfig/openshift-console
%else
mv %{buildroot}%{consoledir}/init.d/* %{buildroot}%{_initddir}
%endif
rm -rf %{buildroot}%{consoledir}/init.d
rm -rf %{buildroot}%{consoledir}/systemd

ln -s %{consoledir}/public %{buildroot}%{htmldir}/console
mv %{buildroot}%{consoledir}/etc/openshift/* %{buildroot}%{_sysconfdir}/openshift
cp %{buildroot}%{_sysconfdir}/openshift/console.conf %{buildroot}%{_sysconfdir}/openshift/console-dev.conf
rm -rf %{buildroot}%{consoledir}/etc
mv %{buildroot}%{consoledir}/.openshift/api.yml %{buildroot}%{openshiftconfigdir}
ln -sf %{_libdir}/httpd/modules %{buildroot}%{consoledir}/httpd/modules
ln -sf /etc/httpd/conf/magic %{buildroot}%{consoledir}/httpd/conf/magic

%if 0%{?fedora}
rm %{buildroot}%{consoledir}/httpd/console-scl-ruby193.conf
%endif
%if 0%{?rhel}
rm %{buildroot}%{consoledir}/httpd/console.conf
mv %{buildroot}%{consoledir}/httpd/console-scl-ruby193.conf %{buildroot}%{consoledir}/httpd/console.conf
%endif

%if 0%{?fedora} >= 18
mv %{buildroot}%{consoledir}/httpd/httpd.conf.apache-2.4 %{buildroot}%{consoledir}/httpd/httpd.conf
%else
mv %{buildroot}%{consoledir}/httpd/httpd.conf.apache-2.3 %{buildroot}%{consoledir}/httpd/httpd.conf
%endif
rm %{buildroot}%{consoledir}/httpd/httpd.conf.apache-*


%clean
rm -rf $RPM_BUILD_ROOT

%preun
if [ "$1" -eq "0" ]; then
%if %{with_systemd}
   /bin/systemctl --no-reload disable openshift-console.service
   /bin/systemctl stop openshift-console.service
%else
   /sbin/service openshift-console stop || :
   /sbin/chkconfig --del openshift-console || :
%endif
fi

%files
%defattr(0640,apache,apache,0750)
%{openshiftconfigdir}
%attr(0750,-,-) %{_var}/log/openshift/console
%attr(0750,-,-) %{_var}/log/openshift/console/httpd
%attr(0750,-,-) %{consoledir}/script
%attr(0750,-,-) %{consoledir}/tmp
%attr(0750,-,-) %{consoledir}/tmp/cache
%attr(0750,-,-) %{consoledir}/tmp/pids
%attr(0750,-,-) %{consoledir}/tmp/sessions
%attr(0750,-,-) %{consoledir}/tmp/sockets
%dir %attr(0750,-,-) %{consoledir}/httpd/conf.d
%{consoledir}
%{htmldir}/console
%config %{consoledir}/config/environments/production.rb
%config %{consoledir}/config/environments/development.rb
%config(noreplace) %{_sysconfdir}/openshift/console.conf
%config(noreplace) %{_sysconfdir}/openshift/console-dev.conf

%defattr(0640,root,root,0750)
%if %{with_systemd}
%{_unitdir}/openshift-console.service
%attr(0644,-,-) %{_unitdir}/openshift-console.service
%{_sysconfdir}/sysconfig/openshift-console
%attr(0644,-,-) %{_sysconfdir}/sysconfig/openshift-console
%else
%{_initddir}/openshift-console
%attr(0750,-,-) %{_initddir}/openshift-console
%endif

%post
/bin/touch %{_var}/log/openshift/console/httpd/error_log
/bin/touch %{_var}/log/openshift/console/httpd/access_log

%if %{with_systemd}
/bin/systemctl --system daemon-reload
/bin/systemctl try-restart openshift-console.service
%else
/sbin/chkconfig --add openshift-console || :
/sbin/service openshift-console condrestart || :
%endif

#selinux updated
/usr/sbin/semanage -i - <<_EOF
fcontext -a -t httpd_log_t '%{_var}/log/openshift/console(/.*)?'
fcontext -a -t httpd_log_t '%{_var}/log/openshift/console/httpd(/.*)?'
fcontext -a -t httpd_var_run_t '%{consoledir}/httpd/run(/.*)?'
_EOF
/sbin/restorecon -R %{_var}/log/openshift/console
/sbin/restorecon -R %{consoledir}

/sbin/fixfiles -R %{?scl:%scl_prefix}rubygem-passenger restore
/sbin/fixfiles -R %{?scl:%scl_prefix}mod_passenger restore
/sbin/restorecon -R -v /var/run
%changelog
* Fri Sep 13 2013 Troy Dawson <tdawson@redhat.com> 1.15.1-1
- Bump up version (tdawson@redhat.com)
- Fixing gem version requirement on sass-twitter-bootstrap (kraman@gmail.com)
- Revert "Update Gemfile". Pushed to wrong branch. (kraman@gmail.com)
- Update Gemfile (kraman@gmail.com)
- Fix origin console rhel build, add -p flag to mkdir (jforrest@redhat.com)
- Adding missing activemq config templates Fixing console spec to require gems
  Additional fixes to comprehensive deployment guide (kraman@gmail.com)
- Fixing comprehensive doc to include latest changes in broker/node setup.
  Fixing openshift-origin-auth-remote-user-* for Apache 2.2 and 2.4 Fixing
  openshift-origin-console.spec to include missing gems (kraman@gmail.com)
- Bug 985656 - minor improvement for consistency in broker and console spec
  files (bleanhar@redhat.com)
- Merge pull request #2946 from maxamillion/dev/maxamillion/enable_rhcl
  (dmcphers+openshiftbot@redhat.com)
- enable rhscl repos - add wrapper (admiller@redhat.com)
- KrbLocalUserMapping enables conversion to local users.
  (jpazdziora@redhat.com)