Name:           pam-openshift
Version:        0.99.14
Release:        1%{?dist}
Summary:        Openshift PAM module
Group:          System Environment/Base
License:        GPLv2
URL:            http://www.openshift.com/
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:  pam-devel libselinux-devel libattr-devel gcc-c++ make

Provides:       pam-libra
Obsoletes:      pam-libra

%description
The Openshift PAM module configures proper SELinux context for
processes in a session.

%prep
%setup -q

%build
make CFLAGS="%{optflags}"

%install
rm -rf $RPM_BUILD_ROOT

install -D -m 755 pam_openshift.so.1 %{buildroot}/%{_lib}/security/pam_openshift.so
ln -s pam_openshift.so %{buildroot}/%{_lib}/security/pam_libra.so
install -D -m 644 pam_openshift.8 %{buildroot}/%{_mandir}/man8/pam_openshift.8

install -D -m 755 oo-namespace-init %{buildroot}/%{_sbindir}/oo-namespace-init

mkdir -p %{buildroot}/%{_sysconfdir}/security/namespace.d
install -D -m 644 namespace.d/* %{buildroot}/%{_sysconfdir}/security/namespace.d

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(0644, root, root)
%doc AUTHORS ChangeLog COPYING README README.xml
%attr(0755,root,root) /%{_lib}/security/pam_openshift.so
%attr(0755,root,root) /%{_lib}/security/pam_libra.so
%attr(0644,root,root) %{_mandir}/man8/pam_openshift.8.gz
%attr(0755,root,root) %{_sbindir}/oo-namespace-init
%attr(0644,root,root) %config(noreplace) %{_sysconfdir}/security/namespace.d/*

%changelog
* Wed Oct 17 2012 Krishna Raman <kraman@gmail.com> 0.99.14-1
- Do not setup sandbox by default. (rmillner@redhat.com)
- Add pam-namespace. (rmillner@redhat.com)
- Move SELinux to Origin and use new policy definition. (rmillner@redhat.com)

* Wed Oct 10 2012 Rob Millner <rmillner@redhat.com> 0.99.13-1
- Move SELinux to Origin and use new policy definition. (rmillner@redhat.com)

* Wed Oct 10 2012 Rob Millner <rmillner@redhat.com> 0.99.12-1
- Install our changes into pam. (rmillner@redhat.com)

* Wed Oct 10 2012 Rob Millner <rmillner@redhat.com> 0.99.11-1
- Update tags from rebase
* Wed Oct 10 2012 Rob Millner <rmillner@redhat.com> 0.99.10-1
- Provide/obsolete pam-libra for devenv build. (rmillner@redhat.com)

* Wed Oct 10 2012 Rob Millner <rmillner@redhat.com> 0.99.9-1
- Automatic commit of package [pam-openshift] release [0.99.8-1].
  (rmillner@redhat.com)
- Move SELinux to Origin and use new policy definition. Include backport
  selinux package. (rmillner@redhat.com)

* Wed Oct 10 2012 Rob Millner <rmillner@redhat.com> 0.99.8-1
- Move SELinux to Origin and use new policy definition. Include backport
  selinux package. (rmillner@redhat.com)

* Tue Oct 09 2012 Rob Millner <rmillner@redhat.com> 0.99.7-1
- Automatic commit of package [pam-openshift] release [0.99.6-1].
  (rmillner@redhat.com)
- Move pam-openshift to the top level directory (rmillner@redhat.com)

* Fri Oct 05 2012 Rob Millner <rmillner@redhat.com> 0.99.6-1
- Move pam-openshift to the top level directory (rmillner@redhat.com)

* Fri Oct 05 2012 Rob Millner <rmillner@redhat.com> 0.99.5-1
- Minor specfile cleanup (rmillner@redhat.com)
- Needed to quote the optflags. (rmillner@redhat.com)
- Add optflags from RPM for the build. (rmillner@redhat.com)
- Obtain correct version of GPLv2 license file. (rmillner@redhat.com)

* Fri Oct 05 2012 Rob Millner <rmillner@redhat.com> 0.99.4-1
- Read the SELinux context of the users home directory to determine if the
  policy applies. (rmillner@redhat.com)
- Rpmlint fixes. (rmillner@redhat.com)

* Wed Oct 03 2012 Rob Millner <rmillner@redhat.com> 0.99.3-1
- Specfile fixes (rmillner@redhat.com)

* Wed Oct 03 2012 Rob Millner <rmillner@redhat.com> 0.99.2-1
- Created pam-openshift package

