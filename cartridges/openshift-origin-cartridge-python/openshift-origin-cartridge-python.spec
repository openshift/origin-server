%global cartridgedir %{_libexecdir}/openshift/cartridges/python
%global httpdconfdir /etc/openshift/cart.conf.d/httpd/python

Name:          openshift-origin-cartridge-python
Version: 1.21.0
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

%if 0%{?fedora}%{?rhel} <= 6
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.rhel %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%if 0%{?fedora} == 19
%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.f19 %{buildroot}%{cartridgedir}/metadata/manifest.yml
%endif
%__rm -f %{buildroot}%{cartridgedir}/metadata/manifest.yml.*


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
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
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
