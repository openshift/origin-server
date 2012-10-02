Name:           stickshift-selinux
Version:        1.0.1
Release:        1%{?dist}
Summary:        Stickshift SELinux policies

License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

Requires:       selinux-policy-targeted
Requires:       policycoreutils-python

%description
Stickshfit SELinux policies

%prep
%setup -q


%build
make -f /usr/share/selinux/devel/Makefile

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p %{buildroot}%{_datadir}/selinux/packages/%{name}
install -m 644 *.pp %{buildroot}%{_datadir}/selinux/packages/%{name}

%post
semodule -i /usr/share/selinux/packages/%{name}/*.pp

%files
%defattr(-,root,root,-)
%doc LICENSE README
/usr/share/selinux/packages/%{name}/


%changelog
* Mon Oct 01 2012 Rob Millner <rmillner@redhat.com> 1.0.1-1
- Updated to openshift 1.0 policies


* Fri Sep 28 2012 Rob Millner <rmillner@redhat.com> 0.1.1-1
- Move stickshift selinux policies into their own RPM.

