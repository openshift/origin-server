%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-routing-daemon
%global rubyabi 1.9.1
%global appdir %{_var}/lib/openshift
%global apprundir %{_var}/run/openshift

Summary:       OpenShift daemon for routing integration
Name:          rubygem-%{gem_name}
Version: 0.26.4
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://openshift.redhat.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/rubygem-%{gem_name}-%{version}.tar.gz
%if 0%{?fedora} >= 19
Requires:      ruby(release)
%else
Requires:      %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
Requires:      openshift-origin-util-scl
%endif
Requires:      %{?scl:%scl_prefix}rubygems
Requires:      %{?scl:%scl_prefix}rubygem(daemons)
Requires:      %{?scl:%scl_prefix}rubygem(json)
Requires:      %{?scl:%scl_prefix}rubygem(parseconfig)
Requires:      %{?scl:%scl_prefix}rubygem(rest-client)
Requires:      %{?scl:%scl_prefix}rubygem(stomp)
Requires:      rubygem(openshift-origin-common)
%if 0%{?fedora}%{?rhel} <= 6
BuildRequires: %{?scl:%scl_prefix}build
BuildRequires: scl-utils-build
%endif
%if 0%{?fedora} >= 19
BuildRequires: ruby(release)
%else
BuildRequires: %{?scl:%scl_prefix}ruby(abi) >= %{rubyabi}
%endif
BuildRequires: %{?scl:%scl_prefix}rubygems
BuildRequires: %{?scl:%scl_prefix}rubygems-devel
BuildArch:     noarch

%description
OpenShift daemon for routing integration.

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}
gem build %{gem_name}.gemspec
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_root_bindir} \
        --force %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}/%{_var}/log/openshift

mkdir -p %{buildroot}%{_root_sbindir}
cp bin/oo-* %{buildroot}%{_root_sbindir}/

mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}/etc/openshift
mv %{buildroot}%{gem_instdir}/conf/* %{buildroot}/etc/openshift

mkdir -p %{buildroot}/etc/rc.d/init.d/
cp -a init/* %{buildroot}/etc/rc.d/init.d/

%files
%dir %{gem_instdir}
%dir %{gem_dir}
%doc Gemfile LICENSE
%{gem_dir}/doc/%{gem_name}-%{version}
%{gem_dir}/gems/%{gem_name}-%{version}
%{gem_dir}/cache/%{gem_name}-%{version}.gem
%{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
%config(noreplace) /etc/openshift/routing-daemon.conf
%attr(0755,-,-) /etc/rc.d/init.d/openshift-routing-daemon
%attr(0750,-,-) %{_root_sbindir}/oo-admin-ctl-routing
%attr(0755,-,-) %{_var}/log/openshift

%changelog
* Thu Oct 15 2015 Stefanie Forrester <sedgar@redhat.com> 0.26.4-1
- Set the Host header appropriately in Nginx alias configuration
  (tiwillia@redhat.com)

* Mon Oct 12 2015 Stefanie Forrester <sedgar@redhat.com> 0.26.3-1
- routing-daemon: F5: Support multiple hosts (miciah.masters@gmail.com)
- routing-daemon: F5: Fix policy if broken (miciah.masters@gmail.com)
- routing-daemon: F5: Use const POLICY_NAME (miciah.masters@gmail.com)

* Tue Sep 22 2015 Stefanie Forrester <sedgar@redhat.com> 0.26.2-1
- Merge pull request #6242 from Miciah/routing-daemon-f5-fix-syntax-error
  (dmcphers+openshiftbot@redhat.com)
- routing-daemon: F5: Fix syntax error (miciah.masters@gmail.com)

* Thu Sep 17 2015 Unknown name 0.26.1-1
- bump_minor_versions for sprint 103 (sedgar@jhancock.ose.phx2.redhat.com)

* Thu Sep 17 2015 Unknown name 0.25.2-1
- routing-daemon: F5: Fix initialization (miciah.masters@gmail.com)
- routing-daemon: F5: Sync device-group on update (miciah.masters@gmail.com)
- routing-daemon: controllers: invoke model update (miciah.masters@gmail.com)
- routing-daemon: Delete read_config in controllers (miciah.masters@gmail.com)
- routing-daemon: F5: Fix variable names & comments (miciah.masters@gmail.com)
- routing-daemon: F5: check for and log SSH errors (miciah.masters@gmail.com)
- routing-daemon: F5: Use configured SSH user (rhowe@redhat.com)

* Thu Jul 02 2015 Wesley Hearn <whearn@redhat.com> 0.25.1-1
- bump_minor_versions for 2.0.65 (whearn@redhat.com)

* Thu May 07 2015 Troy Dawson <tdawson@redhat.com> 0.24.2-1
- Attempting to fix BZ 1212020 (sferich888@gmail.com)

* Fri Apr 10 2015 Wesley Hearn <whearn@redhat.com> 0.24.1-1
- bump_minor_versions for sprint 62 (whearn@redhat.com)

* Mon Mar 30 2015 Troy Dawson <tdawson@redhat.com> 0.23.3-1
- Merge pull request #6112 from Miciah/bug-1199904-routing-daemon-fixes
  (dmcphers+openshiftbot@redhat.com)
- routing-daemon: Try harder to create pool (miciah.masters@gmail.com)
- routing-daemon: Refresh monitors in case of error (miciah.masters@gmail.com)
- oo-admin-ctl-routing: Fix delete-monitor error msg (miciah.masters@gmail.com)
- oo-admin-ctl-routing: Fix delete-monitor help text (miciah.masters@gmail.com)

* Thu Mar 26 2015 Wesley Hearn <whearn@redhat.com> 0.23.2-1
- routing-daemon: add ruby193-rubygem-rest-client dep (sdodson@redhat.com)
- Merge pull request #6102 from Miciah/routing-daemon-monitor-fixes
  (dmcphers+openshiftbot@redhat.com)
- routing-daemon: Use e.message, not e.to_s (miciah.masters@gmail.com)
- oo-admin-ctl-routing: Make delete-monitor cleverer (miciah.masters@gmail.com)
- routing-daemon: Allow list monitors of pool (miciah.masters@gmail.com)
- routing-daemon: Associate/dissociate monitors (miciah.masters@gmail.com)
- oo-admin-ctl-routing delete-monitor: pool optional (miciah.masters@gmail.com)
- routing-daemon: Improve error reporting for F5 (miciah.masters@gmail.com)
- routing-daemon: Fix async delete_monitor arguments (miciah.masters@gmail.com)
- routing-daemon: Fix async create_monitor queueing (miciah.masters@gmail.com)

* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 0.23.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)
- BZ1199904 - Fixing oo-admin-ctl-routing to delete monitors
  (calfonso@redhat.com)
- BZ1199901, BZ1199903, BZ1199904 creating and deleting monitors
  (christopher.alfonso@gmail.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 0.22.2-1
- BZ1187047 - "oo-admin-ctl-routing delete-alias" does not delete..
  (calfonso@redhat.com)
- BZ1186171 - scp needs additional arguments to avoid prompts
  (calfonso@redhat.com)
- Add F5 HTTPS support and removing the routes feature (calfonso@redhat.com)

* Tue Dec 09 2014 Adam Miller <admiller@redhat.com> 0.22.1-1
- bump_minor_versions for sprint 55 (admiller@redhat.com)

* Tue Dec 02 2014 Adam Miller <admiller@redhat.com> 0.21.3-1
- Merge pull request #5992 from Miciah/bug-1169424-some-oo-admin-ctl-routing-
  tool-issues (dmcphers+openshiftbot@redhat.com)
- oo-admin-ctl-routing: Better usage output (miciah.masters@gmail.com)
- oo-admin-ctl-routing: Add list-aliases (miciah.masters@gmail.com)
- oo-admin-ctl-routing: Add list-pool-aliases usage (miciah.masters@gmail.com)
- oo-admin-ctl-routing: Fix list-monitors (miciah.masters@gmail.com)
- oo-admin-ctl-routing usage info: Add missing "|" (miciah.masters@gmail.com)
- oo-admin-ctl-routing: Print usage with no args (miciah.masters@gmail.com)

* Mon Dec 01 2014 Adam Miller <admiller@redhat.com> 0.21.2-1
- routing-daemon: Fix deletion of SSL cert key (miciah.masters@gmail.com)
- BZ1168034 - nginx configuration is broken when multiple applications..
  (calfonso@redhat.com)
- BZ1168036 -  Requests made to the nginx router at '/' are forwarded..
  (calfonso@redhat.com)
- BZ115918 - Added configurable ha dns prefix to routing daemon
  (calfonso@redhat.com)
- BZ1167707 - openshift-routing-daemon miss stomp connection ...
  (calfonso@redhat.com)
- BZ1167949 - non-scaling app creation with HA routing causes NGINX..
  (calfonso@redhat.com)
- Merge pull request #5976 from calfonso/bz1167625
  (dmcphers+openshiftbot@redhat.com)
- BZ1167625 -  Fail to start openshift-routing-daemon service when no port
  (calfonso@redhat.com)
- BZ1166593 - conflicting alias server name is listening on 443
  (calfonso@redhat.com)

* Mon Nov 24 2014 Adam Miller <admiller@redhat.com> 0.21.1-1
- bump_minor_versions for sprint 54 (admiller@redhat.com)
- Merge pull request #5973 from calfonso/bz1166518
  (dmcphers+openshiftbot@redhat.com)
- BZ1166518 - rubygem-openshift-origin-common should be installed...
  (calfonso@redhat.com)
- BZ1166600 - routing-daemon will add duplicated route (calfonso@redhat.com)
- BZ1158773 - openshift-routing-daemon always return success even...
  (calfonso@redhat.com)
- BZ1165606 - enable activemq ssl connections for routing (calfonso@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 0.20.2-1
- BZ#1159392 - Add HTTPS configuration for all applications with NGINX
  (calfonso@redhat.com)
- BZ#1160860 - Update routing-daemon.conf setting defaults for NGINX to 1.6
  (calfonso@redhat.com)
- Fixes bz1158773 - openshift-routing-daemon always return success...
  (calfonso@redhat.com)
- bz#1157863 - rubygem-openshift-origin-routing-daemon needs to set the file
  mode (calfonso@redhat.com)
- bz#1156613 - Turn off NGINX PLus by default (calfonso@redhat.com)
- add significant digit to verison number for build automation
  (admiller@redhat.com)

* Wed Oct 22 2014 Adam Miller <admiller@redhat.com> 0.20-1
- Adding NGINX Plus health checks to routing-daemon (calfonso@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 0.19-1
- Adding SSL configuration for nginx (calfonso@redhat.com)

* Mon Oct 13 2014 Troy Dawson <tdawson@redhat.com> 0.18-1
- Creating tito tag for origin-server git repo

* Tue Sep 17 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.17-1
- controllers/lbaas.rb: Handle "PROCESSING" status (miciah.masters@gmail.com)

* Tue Sep 17 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.16-1
- Put routing executables under root (miciah.masters@gmail.com)

* Tue Sep 17 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.15-1
- Merge routing RPMs (miciah.masters@gmail.com)
- Add export notice to routing README.md (miciah.masters@gmail.com)

* Tue Sep 17 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.14-1
- Add openshift-routing-daemon initscript (miciah.masters@gmail.com)

* Wed Sep 04 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.13-1
- controllers/lbaas.rb: Fix delete_monitor (miciah.masters@gmail.com)

* Wed Sep 04 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.12-1
- Delete monitor on app delete if it's not shared (miciah.masters@gmail.com)

* Mon Aug 12 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.11-1
- Make monitor timeout configurable (miciah.masters@gmail.com)

* Mon Aug 05 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.10-1
- Make monitor interval configurable (miciah.masters@gmail.com)
- Make monitor type configurable (miciah.masters@gmail.com)

* Thu Aug 01 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.9-1
- Make monitor up code configurable (miciah.masters@gmail.com)

* Tue Jul 30 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.8-1
- Make pool and route names configurable (miciah.masters@gmail.com)

* Mon Jul 29 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.7-1
- Expose dummy model (miciah.masters@gmail.com)

* Thu Jul 25 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.6-1
- daemon.rb: delete_pool even if delete_route fails (miciah.masters@gmail.com)

* Wed Jul 24 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.5-1
- Fix backtrace logging output (miciah.masters@gmail.com)

* Wed Jul 24 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.4-1
- Use Logger for output (miciah.masters@gmail.com)

* Wed Jul 17 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.3-1
- 

* Wed Jul 17 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.2-1
- Load F5/LBaaS backends conditionally (miciah.masters@gmail.com)

* Tue Jul 09 2013 Miciah Dashiel Butler Masters <mmasters@redhat.com> 0.1-1
- new package built with tito

