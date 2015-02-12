Summary:       Utility scripts for the OpenShift Origin broker and node
Name:          openshift-origin-util-scl
Version: 1.20.1
Release:       1%{?dist}
Group:         Network/Daemons
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
BuildArch:     noarch

%description
This package contains a set of utility scripts for the broker and node. 

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}%{_bindir}
cp oo-* %{buildroot}%{_bindir}/

%files
%attr(0755,-,-) %{_bindir}/oo-ruby
%attr(0755,-,-) %{_bindir}/oo-erb
%attr(0755,-,-) %{_bindir}/oo-exec-ruby
%attr(0755,-,-) %{_bindir}/oo-mco


%changelog
* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.20.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.19.2-1
- Bug 1154521 - Fix the case when the system ruby is not installed
  (mfojtik@redhat.com)
- Use /usr/bin/ruby to determine the system ruby version instead of rpm
  (mfojtik@redhat.com)
- have oo-exec-ruby handle scl, non-scl, and error on too old version of ruby
  (admiller@redhat.com)
- Revert "oo-mco is ruby193 specific and depends on scl directly, call scl
  ruby193 directly" (admiller@redhat.com)
- oo-mco is ruby193 specific and depends on scl directly, call scl ruby193
  directly (admiller@redhat.com)
- let oo-exec-ruby handle scl and non-scl for various reasons
  (admiller@redhat.com)

* Thu Sep 18 2014 Adam Miller <admiller@redhat.com> 1.19.1-1
- bump_minor_versions for sprint 51 (admiller@redhat.com)

* Tue Sep 09 2014 Adam Miller <admiller@redhat.com> 1.18.2-1
- util-scl/oo-mco: Added error message when scl mco does not exist.
  (tiwillia@redhat.com)

* Thu Jun 05 2014 Adam Miller <admiller@redhat.com> 1.18.1-1
- bump_minor_versions for sprint 46 (admiller@redhat.com)

* Fri May 16 2014 Adam Miller <admiller@redhat.com> 1.17.2-1
- update oo-exec-ruby for RHSCL-1.1, requires v8 runtime paths also
  (admiller@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.17.1-1
- Merge pull request #4742 from Miciah/bug-1017248-oo-ruby-does-not-set-up-the-
  correct-environment-in-a-nested-invocation (dmcphers+openshiftbot@redhat.com)
- oo-exec-ruby: Set PATH &c. directly, not using scl (miciah.masters@gmail.com)
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.16.2-1
- Cleaning specs (dmcphers@redhat.com)

* Mon Oct 21 2013 Adam Miller <admiller@redhat.com> 1.16.1-1
- bump_minor_versions for sprint 35 (admiller@redhat.com)