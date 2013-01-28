Summary:        Utility scripts for the OpenShift Origin broker and node
Name:           openshift-origin-util
Version:        1.0.4
Release:        1%{?dist}
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:       bind-utils
Requires:       ruby
Requires:       rubygems
BuildArch:      noarch

%description
This package contains a set of utility scripts for the
OpenShift broker and node. 

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_bindir}
cp oo-* %{buildroot}%{_bindir}/
chmod 0755 %{buildroot}%{_bindir}/*

%files
%{_bindir}/oo-ruby
%{_bindir}/oo-exec-ruby
%{_bindir}/oo-diagnostics


%changelog
* Mon Jan 28 2013 Krishna Raman <kraman@gmail.com> 1.0.4-1
- Merge pull request #1132 from tdawson/tdawson/fed-update/util-1.0.3
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1153 from pmorie/bugs/875910
  (dmcphers+openshiftbot@redhat.com)
- fix the dns prereq test; no more false positives (lmeyer@redhat.com)
- Fix BZ875910: make oo-accept-node extensible (pmorie@gmail.com)
- spec file cleanup (tdawson@redhat.com)
- Testing for altered packaged-owned configs (calfonso@redhat.com)
- add oo-diag tests for: chkconfig services missing, quota bug, rogue vhost.
  also abortok flag. (lmeyer@redhat.com)
- Updates to oo-diagnostics. Mainly, added tests for 3-way consistency between
  conf, node hosts, and districts. Added a pass for some enterprise RPMs that
  didn't get the right dist. Amended top instructions to describe output
  levels. Place DNS test first to enable bailing out early. Run oo-accept-
  systems if present. (lmeyer@redhat.com)
- re-enabed ews2 (bdecoste@gmail.com)
- Adding tests for broken nameserver, stale cartridge cache, broken PAM setup.
  Also some better error recovery if broker app env doesn't load.
  (lmeyer@redhat.com)
- use env ruby; add mco TTL check (lmeyer@redhat.com)
- adding oo-diagnostics script (lmeyer@redhat.com)
- use /bin/env for cron (dmcphers@redhat.com)
- Working around scl enable limitations with parameter passing
  (dmcphers@redhat.com)
- add oo-ruby (dmcphers@redhat.com)

* Wed Nov 21 2012 Dan McPherson <dmcphers@redhat.com> 1.0.3-1
- Bumped to new version

* Wed Nov 21 2012 Dan McPherson <dmcphers@redhat.com> 1.0.2-1
- new package built with tito

* Wed Nov 21 2012 Dan McPherson <dmcphers@redhat.com> 1.0.1-1
- new package built with tito

* Wed Nov 21 2012 Dan McPherson <dmcphers@redhat.com> 1.0.0-1
- Initial commit
