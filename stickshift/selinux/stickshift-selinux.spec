Name:           stickshift-selinux
Version:        0.1.1
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
mkdir -p %{buildroot}%{_datadir}/selinux/packages/stickshift.pp
install -m 644 stickshift.pp %{buildroot}%{_datadir}/selinux/packages/

%post
semodule -i /usr/share/selinux/packages/stickshift.pp

%files
%defattr(-,root,root,-)
%doc LICENSE
/usr/share/selinux/packages/%{name}/


%changelog
* Fri Sep 28 2012 Rob Millner <rmillner@redhat.com> 0.1.1-1
- Move stickshift selinux policies into their own RPM.

