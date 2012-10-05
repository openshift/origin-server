Name:           pam-openshift
Version:        0.99.4
Release:        1%{?dist}
Summary:        Openshift PAM module
Group:          System Environment/Base
License:        GPLv2
URL:            http://www.openshift.com/
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:  pam-devel libselinux-devel libattr-devel gcc-c++ make

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
install -D -m 644 pam_openshift.8 %{buildroot}/%{_mandir}/man8/pam_openshift.8

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(0644, root, root)
%doc AUTHORS ChangeLog COPYING README README.xml
%attr(0755,root,root) /%{_lib}/security/pam_openshift.so
%attr(0644,root,root) %{_mandir}/man8/pam_openshift.8.gz


%changelog
* Fri Oct 05 2012 Rob Millner <rmillner@redhat.com> 0.99.4-1
- Read the SELinux context of the users home directory to determine if the
  policy applies. (rmillner@redhat.com)
- Rpmlint fixes. (rmillner@redhat.com)
* Wed Oct 03 2012 Rob Millner <rmillner@redhat.com> 0.99.3-1
- Specfile fixes (rmillner@redhat.com)

* Wed Oct 03 2012 Rob Millner <rmillner@redhat.com> 0.99.2-1
- Created pam-openshift package

