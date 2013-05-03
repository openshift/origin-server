%global cartridgedir %{_libexecdir}/openshift/cartridges/python-3.3

Summary:       Provides support for using community Python 3.3 cartridge
Name:          openshift-origin-cartridge-community-python-3.3
Version: 0.5.2
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      openshift-origin-cartridge-abstract
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      httpd
Requires:	   python-virtualenv
Requires:      redhat-lsb-core
BuildRequires: git
BuildArch:     noarch

%description
Provides support for using a community python 3.3 cartridge on OpenShift


%prep
%setup -q


%build

%install
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/data/
mkdir -p %{buildroot}%{cartridgedir}/info/connection-hooks/
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
cp -rp info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
ln -s %{cartridgedir}/../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../abstract/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-gear-endpoint %{buildroot}%{cartridgedir}/info/connection-hooks/publish-gear-endpoint
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-http-url %{buildroot}%{cartridgedir}/info/connection-hooks/publish-http-url
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-nosql-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-nosql-db-connection-info
ln -s %{cartridgedir}/../abstract/info/bin/sync_gears.sh %{buildroot}%{cartridgedir}/info/bin/sync_gears.sh

%files
%doc COPYRIGHT LICENSE
%dir %{cartridgedir}
%dir %{cartridgedir}/info
%attr(0755,-,-) %{cartridgedir}/info/hooks
%attr(0750,-,-) %{cartridgedir}/info/hooks/*
%attr(0755,-,-) %{cartridgedir}/info/hooks/tidy
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/lib/
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Fri May 03 2013 Adam Miller <admiller@redhat.com> 0.5.2-1
- Bugs 958709, 958744, 958757 (dmcphers@redhat.com)

* Thu Apr 25 2013 Adam Miller <admiller@redhat.com> 0.5.1-1
- Update outdated links in 'cartridges' directory. (asari.ruby@gmail.com)
- Bug 928675 (asari.ruby@gmail.com)
- bump_minor_versions for sprint 2.0.26 (tdawson@redhat.com)

* Fri Apr 12 2013 Adam Miller <admiller@redhat.com> 0.4.3-1
- SELinux, ApplicationContainer and UnixUser model changes to support oo-admin-
  ctl-gears operating on v1 and v2 cartridges. (rmillner@redhat.com)

* Wed Apr 10 2013 Adam Miller <admiller@redhat.com> 0.4.2-1
- Delete move/pre-move/post-move hooks, these hooks are no longer needed.
  (rpenta@redhat.com)

* Thu Mar 28 2013 Adam Miller <admiller@redhat.com> 0.4.1-1
- bump_minor_versions for sprint 26 (admiller@redhat.com)
- add Requires for F18 (bdecoste@gmail.com)

* Thu Mar 14 2013 Adam Miller <admiller@redhat.com> 0.3.2-1
- Refactor Endpoints to support frontend mapping (ironcladlou@gmail.com)
- remove old obsoletes (tdawson@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 0.3.1-1
- bump_minor_versions for sprint 25 (admiller@redhat.com)

* Thu Mar 07 2013 Adam Miller <admiller@redhat.com> 0.2.4-1
- Bug 919161: Fix Python 3.3 Endpoint entry (ironcladlou@gmail.com)
- Bug 918383 - Python community cartridges cannot share virtualenv
  (jhonce@redhat.com)

* Tue Feb 19 2013 Adam Miller <admiller@redhat.com> 0.2.3-1
- Audit of remaining front-end Apache touch points. (rmillner@redhat.com)
- Bug 903530 Set version to framework version (dmcphers@redhat.com)

* Fri Feb 08 2013 Adam Miller <admiller@redhat.com> 0.2.2-1
- change %%define to %%global (tdawson@redhat.com)

* Thu Feb 07 2013 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 24 (admiller@redhat.com)

* Wed Feb 06 2013 Adam Miller <admiller@redhat.com> 0.1.7-1
- make Source line uniform among all spec files (tdawson@redhat.com)

* Tue Feb 05 2013 Adam Miller <admiller@redhat.com> 0.1.6-1
- Bug 907426 - [US3327]Jenkins build failed for python-2.7/python-3.3 apps
  (smitram@gmail.com)
- Bug 907372 - [US3327]Meet error "could not create 'YourAppName.egg-info':
  Permission denied" when snapshot restored for python-2.7/python-3.3 apps
  (smitram@gmail.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 0.1.5-1
- Ensure python is tagged vith versions (ccoleman@redhat.com)

* Mon Feb 04 2013 Adam Miller <admiller@redhat.com> 0.1.4-1
- Fix community git url to the openshift forked version (thanks kraman for
  forking that) of the cartridges. (smitram@gmail.com)

* Fri Feb 01 2013 Adam Miller <admiller@redhat.com> 0.1.3-1
- Fix bug where first provider is used by the broker and it ends up switching
  between python 2.7 and python 3.3 on a db add. Set the first provider to the
  specific cartridge name. (smitram@gmail.com)
- Cleanup old/first invalid changelog entry. (smitram@gmail.com)

* Thu Jan 31 2013 Adam Miller <admiller@redhat.com> 0.1.2-1
- new package built with tito

* Wed Jan 30 2013 Ram Ranganathan <ramr@redhat.com> 0.1.1-1
- new package built with tito
