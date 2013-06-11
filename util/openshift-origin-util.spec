%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif

Summary:       Utility scripts for the OpenShift Origin broker and node
Name:          openshift-origin-util
Version:       1.10.2
Release:       1%{?dist}
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      bind-utils
Requires:      %{?scl:%scl_prefix}ruby
Requires:      %{?scl:%scl_prefix}rubygems
BuildArch:     noarch

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
%{_bindir}/oo-erb
%{_bindir}/oo-exec-ruby


%changelog
* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.2-1
- <util> remove oo-diagnostics from spec file (lmeyer@redhat.com)
- Revert "<util> removing legacy package" - Fedora Origin is using
  (lmeyer@redhat.com)
- <util> removing legacy package (lmeyer@redhat.com)
- <common> add oo-diagnostics and man page (lmeyer@redhat.com)
- <oo-diagnostics> modernize and improve (lmeyer@redhat.com)
- Bug 928675 (asari.ruby@gmail.com)

* Tue Jun 11 2013 Troy Dawson <tdawson@redhat.com> 1.10.1-1
- Bump up version to 1.10

* Sat Apr 13 2013 Krishna Raman <kraman@gmail.com> 1.5.2-1
- Fix how erb binary is resolved. Using util/util-scl packages instead of doing
  it dynamically in code. Separating manifest into RHEL and Fedora versions
  instead of using sed to set version. (kraman@gmail.com)
- <oo-diagnostics> bug 916896 check for crond service on node.
  (lmeyer@redhat.com)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.1-1
- <oo-diagnostics> add selinux enforcing check; fix small bug in cache test
  (lmeyer@redhat.com)

* Tue Mar 12 2013 Troy Dawson <tdawson@redhat.com> 1.5.0-1
- Update to version 1.5.0

* Mon Feb 25 2013 Adam Miller <admiller@redhat.com> 1.4.1-2
- bump Release for fixed build target rebuild (admiller@redhat.com)
- <oo-diagnostics> fix bug in District methods, redirect httpd broken version
  to kbase (lmeyer@redhat.com)
- Fixes for ruby193 (john@ibiblio.org)

* Fri Feb 15 2013 Troy Dawson <tdawson@redhat.com> 1.4.1-1
- change %%define to %%global (tdawson@redhat.com)
- <oo-diagnostics> many minor fixes, notices about bzs 893884+849558+892871,
  check for services enabled (lmeyer@redhat.com)
- move rest api tests to functionals (dmcphers@redhat.com)
- <oo-stats, oo-diagnostics> allow -w .5, improve options errmsg
  (lmeyer@redhat.com)
- Merge pull request #1247 from tdawson/tdawson/openshift-origin-console-0.4.1
  (dmcphers+openshiftbot@redhat.com)
- Merge pull request #1133 from mscherer/fix_oodiag_regexp
  (dmcphers+openshiftbot@redhat.com)
- finishing touches of move from openshift-console to openshift-origin-console
  (tdawson@redhat.com)
- be more precise with locate, as the current shell command also match :
  /var/lib/mock/epel-6-x86_64/root/builddir/.rpmmacros
  /home/misc/checkout/git/config/modules/pgsql/manifests/monitor/.rpms.swp
  (misc@zarb.org)
- use a more precise match, since using grep would also result into matching
  mlocate-debuginfo, or anything with mlocate in the name (misc@zarb.org)

* Fri Feb 08 2013 Troy Dawson <tdawson@redhat.com> 1.4.0-1
- Update to version 1.4.0

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
