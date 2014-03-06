# RHEL has 0.6 and 0.10. but 0.10 has a prefix for SCL
# Fedora 18 and 19 has 0.10 as the default
%if 0%{?fedora}%{?rhel} <= 6
  %global scl nodejs010
  %global scl_prefix nodejs010-
%endif

%global cartridgedir %{_libexecdir}/openshift/cartridges/nodejs

Summary:       Provides Node.js support
Name:          openshift-origin-cartridge-nodejs
Version: 1.22.3
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
%if 0%{?fedora}%{?rhel} <= 6
Requires:      %{scl}
%endif
Requires:      %{?scl:%scl_prefix}npm
Requires:      %{?scl:%scl_prefix}nodejs-pg
Requires:      %{?scl:%scl_prefix}nodejs-options
Requires:      %{?scl:%scl_prefix}nodejs-supervisor
Requires:      %{?scl:%scl_prefix}nodejs-async
Requires:      %{?scl:%scl_prefix}nodejs-express
Requires:      %{?scl:%scl_prefix}nodejs-connect
Requires:      %{?scl:%scl_prefix}nodejs-mongodb
Requires:      %{?scl:%scl_prefix}nodejs-mysql
Requires:      %{?scl:%scl_prefix}nodejs-node-static
Requires:      nodejs
Requires:      nodejs-async
Requires:      nodejs-connect
Requires:      nodejs-express
Requires:      nodejs-mongodb
Requires:      nodejs-mysql
Requires:      nodejs-node-static
Requires:      nodejs-pg
Requires:      nodejs-supervisor
Requires:      nodejs-options
Provides:      openshift-origin-cartridge-nodejs-0.6 = 2.0.0
Obsoletes:     openshift-origin-cartridge-nodejs-0.6 <= 1.99.9
BuildArch:     noarch

%description
Provides Node.js support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec
%__rm logs/.gitkeep
find versions/ -name .gitignore -delete
find versions/ -name .gitkeep -delete

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

%if 0%{?rhel}
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/lib/nodejs_context.rhel %{buildroot}%{cartridgedir}/lib/nodejs_context
%endif
%if 0%{?fedora}
%__rm -f %{buildroot}%{cartridgedir}/versions/0.6
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.fedora %{buildroot}%{cartridgedir}/metadata/manifest.yml
%__mv %{buildroot}%{cartridgedir}/lib/nodejs_context.fedora %{buildroot}%{cartridgedir}/lib/nodejs_context
%endif
%__rm -f %{buildroot}%{cartridgedir}/lib/nodejs_context.*
%__rm -f %{buildroot}%{cartridgedir}/metadata/manifest.yml.*

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Thu Mar 06 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Updating cartridge versions (jhadvig@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- fix bash regexp in upgrade scripts (vvitek@redhat.com)
- Fixing typos (dmcphers@redhat.com)
- Merge pull request #4847 from mfojtik/bugzilla/1071165
  (dmcphers+openshiftbot@redhat.com)
- Bug 1071165 - npm no longer supports its self-signed certificates
  (mfojtik@redhat.com)
- Update nodejs cartridge to support LD_LIBRARY_PATH_ELEMENT
  (mfojtik@redhat.com)
- Template cleanup (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 17 2014 Adam Miller <admiller@redhat.com> 1.21.5-1
- Bug 1065506 - Increase OPENSHIFT_NODEJS_POLL_INTERVAL default value to 10000
  (mfojtik@redhat.com)
- Bug 1065681 - Allows users to specify what folder/files supervisor will watch
  (mfojtik@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.21.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4707 from danmcp/master (dmcphers@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Bug 888714 - Remove gitkeep files from rpms (dmcphers@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Bug 1059374 - Sanitize supervisor_bin/node_bin before pkill
  (mfojtik@redhat.com)
- Cleaning specs (dmcphers@redhat.com)
- Bug 1059142 - Fix 'cartridge_bin' command in nodejs control script
  (mfojtik@redhat.com)
- Store cartridge_pid in bash variable (mfojtik@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- Bug 1059374 - Sanity check pkill in nodejs control script
  (mfojtik@redhat.com)
- Bug 1059144 - Refactored nodejs control script (mfojtik@redhat.com)
- Merge pull request #4593 from mfojtik/card/89
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_89 - Make npm optional and restrict hot_deploy to
  supervisor only (mfojtik@redhat.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.20.6-1
- Bump up cartridge versions (bparees@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- Merge pull request #4462 from bparees/cart_data_cleanup
  (dmcphers+openshiftbot@redhat.com)
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Thu Jan 16 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Bug 1048756 - 503 Service Temporarily Unavailable met when accessing after
  deploying pacman for nodejs-0.6/0.10 app (bparees@redhat.com)

* Thu Jan 09 2014 Troy Dawson <tdawson@redhat.com> 1.20.3-1
- Bug 1033581 - Adding upgrade logic to remove the unneeded
  jenkins_shell_command files (bleanhar@redhat.com)
