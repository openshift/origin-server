Name:           pam-openshift
Version:        0.99.1
Release:        1%{?dist}
Summary:        Openshift PAM module
Group:          System Environment/Base
License:        GPLv2
URL:            http://www.openshift.com/
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  pam-devel libselinux-devel gcc-c++ make

%description

The Openshift PAM module configures proper SELinux context for
processes in a session.

%prep
%setup -q


%build
make


%install
rm -rf $RPM_BUILD_ROOT

install -D -m 755 pam_openshift.so.1 %{buildroot}/%{_lib}/security/pam_openshift.so
install -D -m 644 pam_openshift.8 %{buildroot}/%{_mandir}/man8/pam_openshift.8

%files
%doc AUTHORS ChangeLog COPYING README README.xml
%attr(0755,root,root) %{buildroot}/%{_lib}/security/pam_openshift.so
%attr(0644,root,root) %{buildroot}/%{_mandir}/man8/pam_openshift.8


%changelog
