%global cartridgedir %{_libexecdir}/openshift/cartridges/python
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/python

Name:          openshift-origin-cartridge-python
Version: 1.30.0
Release:       1%{?dist}
Summary:       Python cartridge
Group:         Development/Languages
License:       ASL 2.0
URL:           https://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
%if 0%{?fedora}%{?rhel} <= 6
Requires:      python >= 2.6
Requires:      python < 2.7
Requires:      scl-utils
BuildRequires: scl-utils-build
#FIXME: Use %scl_require macro to properly define dependencies
Requires:      python27
Requires:      mod_wsgi >= 3.2
Requires:      mod_wsgi < 3.4
%endif
%if 0%{?fedora} >= 19
Requires:      python >= 2.7
Requires:      python < 2.8
Requires:      mod_wsgi >= 3.4
Requires:      mod_wsgi < 3.5
%endif
Requires:      python-virtualenv
%if 0%{?fedora}%{?rhel} <= 6
Requires:      python27-python-pip-virtualenv
Requires:      python27-mod_wsgi
Requires:      python33-python-virtualenv
Requires:      python33-mod_wsgi
%endif
Provides:      openshift-origin-cartridge-community-python-2.7 = 2.0.0
Provides:      openshift-origin-cartridge-community-python-3.3 = 2.0.0
Provides:      openshift-origin-cartridge-python-2.6 = 2.0.0
Obsoletes:     openshift-origin-cartridge-community-python-2.7 <= 1.99.9
Obsoletes:     openshift-origin-cartridge-community-python-3.3 <= 1.99.9
Obsoletes:     openshift-origin-cartridge-python-2.6 <= 1.99.9
BuildArch:     noarch

%description
Python cartridge for OpenShift. (Cartridge Format V2)


%prep
%setup -q

%build
%__rm %{name}.spec
%__rm logs/.gitkeep
%__rm run/.gitkeep

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}
%__mkdir -p %{buildroot}%{httpdconfdir}

%__mkdir -p %{buildroot}%{cartridgedir}/env

%__mkdir -p %{buildroot}%{cartridgedir}/usr/versions/{2.6,2.7,3.3}
%if 0%{?fedora}%{?rhel} <= 6
%__cp -anv %{buildroot}%{cartridgedir}/usr/versions/2.7-scl/* %{buildroot}%{cartridgedir}/usr/versions/2.7/
%__cp -anv %{buildroot}%{cartridgedir}/usr/versions/3.3-scl/* %{buildroot}%{cartridgedir}/usr/versions/3.3/
%endif
%__cp -anv %{buildroot}%{cartridgedir}/usr/versions/shared/* %{buildroot}%{cartridgedir}/usr/versions/2.6/
%__cp -anv %{buildroot}%{cartridgedir}/usr/versions/shared/* %{buildroot}%{cartridgedir}/usr/versions/2.7/
%__cp -anv %{buildroot}%{cartridgedir}/usr/versions/shared/* %{buildroot}%{cartridgedir}/usr/versions/3.3/

%__rm -rf %{buildroot}%{cartridgedir}/usr/versions/shared
%__rm -rf %{buildroot}%{cartridgedir}/usr/versions/2.7-scl
%__rm -rf %{buildroot}%{cartridgedir}/usr/versions/3.3-scl

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%dir %{httpdconfdir}
%attr(0755,-,-) %{httpdconfdir}
%if 0%{?fedora}%{?rhel} <= 6
%attr(0755,-,-) %{cartridgedir}/usr/versions/2.6/bin/
%attr(0755,-,-) %{cartridgedir}/usr/versions/2.6/bin/*
%endif
%attr(0755,-,-) %{cartridgedir}/usr/versions/2.7/bin/*
%attr(0755,-,-) %{cartridgedir}/usr/versions/3.3/bin/*
%{cartridgedir}/env
%{cartridgedir}/logs
%{cartridgedir}/metadata
%{cartridgedir}/run
%{cartridgedir}/usr
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE
%exclude %{cartridgedir}/usr/versions/*/template/*.pyc
%exclude %{cartridgedir}/usr/versions/*/template/*.pyo

%changelog
* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.29.2-1
- Bug 1151494 - Add WSGIApplicationGroup directive to wsgi.conf
  (mfojtik@redhat.com)

* Fri Aug 08 2014 Adam Miller <admiller@redhat.com> 1.29.1-1
- bump_minor_versions for sprint 49 (admiller@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.28.3-1
- Merge pull request #5673 from bparees/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- bump cart versions for sprint 48 (bparees@redhat.com)

* Wed Jul 30 2014 Adam Miller <admiller@redhat.com> 1.28.2-1
- Bug 1122166 - Preserve sparse files during rsync operations
  (agrimm@redhat.com)

* Fri Jul 18 2014 Adam Miller <admiller@redhat.com> 1.28.1-1
- bump_minor_versions for sprint 48 (admiller@redhat.com)

* Wed Jul 09 2014 Adam Miller <admiller@redhat.com> 1.27.3-1
- Bump cartridge versions for 2.0.47 (jhadvig@gmail.com)

* Thu Jul 03 2014 Adam Miller <admiller@redhat.com> 1.27.2-1
- Bug 1114477: Incorrect pid written into appserver.pid upon python cartridge
  start action (jhadvig@redhat.com)

* Thu Jun 26 2014 Adam Miller <admiller@redhat.com> 1.27.1-1
- bump_minor_versions for sprint 47 (admiller@redhat.com)

* Thu Jun 19 2014 Adam Miller <admiller@redhat.com> 1.26.2-1
- Bump cartridge versions for 2.0.46 (pmorie@gmail.com)
- Making apache server-status optional with a marker (jhadvig@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.26.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Thu May 29 2014 Adam Miller <admiller@redhat.com> 1.25.3-1
- Merge pull request #5465 from ncdc/python-3.3-pip (admiller@redhat.com)
- Add pip installer to the python cartridge (agoldste@redhat.com)
- Bump cartridge versions (agoldste@redhat.com)

* Tue May 27 2014 Adam Miller <admiller@redhat.com> 1.25.2-1
- Make READMEs in template repos more obvious (vvitek@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.25.1-1
- bump_minor_versions for sprint 45 (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com> 1.24.2-1
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller <admiller@redhat.com>
- mass bumpspec to fix tags (admiller@redhat.com)

* Fri Apr 25 2014 Adam Miller - 1.24.0-2
- bumpspec to mass fix tags

* Wed Apr 16 2014 Troy Dawson <tdawson@redhat.com> 1.23.4-1
- Bumping cartridge versions for sprint 43 (bparees@redhat.com)

* Tue Apr 15 2014 Troy Dawson <tdawson@redhat.com> 1.23.3-1
- move libyaml-devel dependency into python cartridge optional dependencies
  (bparees@redhat.com)
- Merge pull request #5260 from ironcladlou/cart-log-vars
  (dmcphers+openshiftbot@redhat.com)
- Re-introduce cartridge-scoped log environment vars (ironcladlou@gmail.com)

* Mon Apr 14 2014 Troy Dawson <tdawson@redhat.com> 1.23.2-1
- Python cartridge suddenly stopped installing dependencies
  (bparees@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.23.1-1
- Removing file listed twice warnings (dmcphers@redhat.com)
- Use named pipes for logshifter redirection where appropriate
  (ironcladlou@gmail.com)
- Bug 1074237 - Exclude python template *.pyc and *.pyo from spec file
  (jhadvig@redhat.com)
- Merge pull request #5168 from mfojtik/bugzilla/1084379
  (dmcphers+openshiftbot@redhat.com)
- Bug 1084379 - Added ensure_httpd_restart_succeed() back into ruby/phpmyadmin
  (mfojtik@redhat.com)
- Bug 1084298 - Fixed typo in python control script (mfojtik@redhat.com)
- Merge pull request #5157 from ironcladlou/httpd-pgroup-fix
  (dmcphers+openshiftbot@redhat.com)
- Force httpd into its own pgroup (ironcladlou@gmail.com)
- Check the return code before writing PID file in Python start_app()
  (mfojtik@redhat.com)
- Fix graceful shutdown logic (ironcladlou@gmail.com)
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Thu Mar 27 2014 Adam Miller <admiller@redhat.com> 1.22.5-1
- Update Cartridge Versions for Stage Cut (vvitek@redhat.com)

* Wed Mar 26 2014 Adam Miller <admiller@redhat.com> 1.22.4-1
- Bug 1080381 - Fixed problem with httpd based carts restart after force-stop
  (mfojtik@redhat.com)
- Report lingering httpd procs following graceful shutdown
  (ironcladlou@gmail.com)

* Tue Mar 25 2014 Adam Miller <admiller@redhat.com> 1.22.3-1
- Port cartridges to use logshifter (ironcladlou@gmail.com)

* Fri Mar 21 2014 Adam Miller <admiller@redhat.com> 1.22.2-1
- Bug 1077591 - Add OPENSHIFT_REPO_DIR to python-path in wsgi
  (mfojtik@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.22.1-1
- Bug 1073934 - Check the ERB safe-level for python openshift.conf.erb
  (mfojtik@redhat.com)
- Removing f19 logic (dmcphers@redhat.com)
- Updating cartridge versions (jhadvig@redhat.com)
- bump_minor_versions for sprint 42 (admiller@redhat.com)

* Wed Mar 05 2014 Adam Miller <admiller@redhat.com> 1.21.3-1
- virtualenv and mod_wsgi are required for python 2.6, 2.7 and 3.3.
  (bleanhar@redhat.com)

* Mon Mar 03 2014 Adam Miller <admiller@redhat.com> 1.21.2-1
- Merge pull request #4862 from VojtechVitek/fix_bash_regexp
  (dmcphers+openshiftbot@redhat.com)
- fix bash regexp in upgrade scripts (vvitek@redhat.com)
- requirements.txt documentation (vvitek@redhat.com)
- Python - DocumentRoot logic, Repository Layout simplification
  (vvitek@redhat.com)
- Update python cartridge to support LD_LIBRARY_PATH_ELEMENT
  (mfojtik@redhat.com)
- Template cleanup (dmcphers@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.21.1-1
- python $OPENSHIFT_PYTHON_REQUIREMENTS_PATH ENV VAR (vvitek@redhat.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Sun Feb 16 2014 Adam Miller <admiller@redhat.com> 1.20.5-1
- httpd cartridges: OVERRIDE with custom httpd conf (lmeyer@redhat.com)

* Wed Feb 12 2014 Adam Miller <admiller@redhat.com> 1.20.4-1
- Merge pull request #4744 from mfojtik/latest_versions
  (dmcphers+openshiftbot@redhat.com)
- Card origin_cartridge_111 - Updated cartridge versions for stage cut
  (mfojtik@redhat.com)
- Merge pull request #4729 from tdawson/2014-02/tdawson/fix-obsoletes
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #4372 from maxamillion/admiller/no_defaulttype_apache24
  (dmcphers+openshiftbot@redhat.com)
- Fix obsoletes and provides (tdawson@redhat.com)
- This directive throws a deprecation warning in apache 2.4
  (admiller@redhat.com)

* Tue Feb 11 2014 Adam Miller <admiller@redhat.com> 1.20.3-1
- Merge pull request #4712 from tdawson/2014-02/tdawson/cartridge-deps
  (dmcphers+openshiftbot@redhat.com)
- Bug 1063677 - Show apache running info when run "rhc cartridge status" for
  python app (jhadvig@redhat.com)
- Merge pull request #4707 from danmcp/master (dmcphers@redhat.com)
- Cleanup cartridge dependencies (tdawson@redhat.com)
- Merge pull request #4559 from fabianofranz/dev/441
  (dmcphers+openshiftbot@redhat.com)
- Bug 888714 - Remove gitkeep files from rpms (dmcphers@redhat.com)
- Removed references to OpenShift forums in several places
  (contact@fabianofranz.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.20.2-1
- Cleaning specs (dmcphers@redhat.com)
- Bug 1060902: Fix relative venv function during install_setup_tools
  (ironcladlou@gmail.com)
- Bug 1060295: Make setup reentrant for cp operations (ironcladlou@gmail.com)
- <httpd carts> bug 1060068: ensure extra httpd conf dirs exist
  (lmeyer@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- Remove community tag from Python manifests (ironcladlou@gmail.com)
- bump_minor_versions for sprint 40 (admiller@redhat.com)

* Thu Jan 23 2014 Adam Miller <admiller@redhat.com> 1.19.8-1
- Bump up cartridge versions (bparees@redhat.com)

* Mon Jan 20 2014 Adam Miller <admiller@redhat.com> 1.19.7-1
- <perl,python,phpmyadmin carts> bug 1055095 (lmeyer@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.6-1
- Merge pull request #4502 from sosiouxme/custom-cart-confs
  (dmcphers+openshiftbot@redhat.com)
- <python cart> enable providing custom gear server confs (lmeyer@redhat.com)

* Fri Jan 17 2014 Adam Miller <admiller@redhat.com> 1.19.5-1
- Merge pull request #4462 from bparees/cart_data_cleanup
  (dmcphers+openshiftbot@redhat.com)
- remove unnecessary cart-data variable descriptions (bparees@redhat.com)

* Tue Jan 14 2014 Adam Miller <admiller@redhat.com> 1.19.4-1
- Merge pull request #4464 from ironcladlou/bz/1052103
  (dmcphers+openshiftbot@redhat.com)
- Bug 1052103: Fix template app.py for Python 3.3 (ironcladlou@gmail.com)

* Mon Jan 13 2014 Adam Miller <admiller@redhat.com> 1.19.3-1
- Merge pull request #4461 from ironcladlou/bz/1052059
  (dmcphers+openshiftbot@redhat.com)
- Bug 1052059: Fix Python 3.3 venv path references (ironcladlou@gmail.com)
- Bug 1051910: Fix Python 2.6 regressions (ironcladlou@gmail.com)
- Merge pull request #4444 from ironcladlou/dev/python-scl
  (dmcphers+openshiftbot@redhat.com)
- Fixing double-slash in python and posgresql cartridge code
  (jhadvig@redhat.com)
- Convert Python 3.3 community cart to use SCL Python 3.3
  (ironcladlou@gmail.com)
