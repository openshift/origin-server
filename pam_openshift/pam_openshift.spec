Summary:       OpenShift PAM module
Name:          pam_openshift
Version: 1.14.1
Release:       1%{?dist}
Group:         System Environment/Base
License:       GPLv2
URL:           http://www.openshift.com/
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
Requires:      policycoreutils
Requires:      attr
BuildRequires: gcc
BuildRequires: pam-devel
BuildRequires: libselinux-devel
BuildRequires: libattr-devel

%description
The OpenShift PAM module configures proper SELinux context for
processes in a session.

%prep
%setup -q

%build
make CFLAGS="%{optflags}"

%install
install -D -m 755 pam_openshift.so.1 %{buildroot}/%{_lib}/security/pam_openshift.so
ln -s pam_openshift.so %{buildroot}/%{_lib}/security/pam_libra.so
install -D -m 644 pam_openshift.8 %{buildroot}/%{_mandir}/man8/pam_openshift.8

install -D -m 755 oo-namespace-init %{buildroot}/%{_sbindir}/oo-namespace-init
install -D -m 644 oo-namespace-init.8 %{buildroot}/%{_mandir}/man8/oo-namespace-init.8


%files
%doc AUTHORS ChangeLog COPYING README README.xml
%attr(0755,root,root) /%{_lib}/security/pam_openshift.so
%attr(0755,root,root) /%{_lib}/security/pam_libra.so
%attr(0644,root,root) %{_mandir}/man8/pam_openshift.8.gz
%attr(0644,root,root) %{_mandir}/man8/oo-namespace-init.8.gz
%attr(0750,root,root) %{_sbindir}/oo-namespace-init

%changelog
* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 1.14.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Thu Feb 19 2015 Adam Miller <admiller@redhat.com> 1.13.2-1
- Fixing typos (dmcphers@redhat.com)

* Tue Nov 11 2014 Adam Miller <admiller@redhat.com> 1.13.1-1
- bump_minor_versions for sprint 53 (admiller@redhat.com)

* Mon Oct 20 2014 Adam Miller <admiller@redhat.com> 1.12.2-1
- Bug 1146750 - Ensure permissions on temporary directories (jhonce@redhat.com)
- Bug 1146750 - Ensure permissions on temporary directories (jhonce@redhat.com)

* Wed Apr 09 2014 Adam Miller <admiller@redhat.com> 1.12.1-1
- bump_minor_versions for sprint 43 (admiller@redhat.com)

* Fri Mar 14 2014 Adam Miller <admiller@redhat.com> 1.11.2-1
- WIP Node Platform - Improve oo-namespace-init performance (jhonce@redhat.com)

* Thu Feb 27 2014 Adam Miller <admiller@redhat.com> 1.11.1-1
- bump_minor_versions for sprint 41 (admiller@redhat.com)

* Mon Feb 10 2014 Adam Miller <admiller@redhat.com> 1.10.3-1
- Cleaning specs (dmcphers@redhat.com)

* Thu Jan 30 2014 Adam Miller <admiller@redhat.com> 1.10.2-1
- Card origin_node_376 - namespace /tmp for non-gear users on Nodes
  (jhonce@redhat.com)