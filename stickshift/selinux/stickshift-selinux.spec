Name:           stickshift-selinux
Version:        1.0.1
Release:        1%{?dist}
Summary:        Stickshift SELinux policies

License:        GPLv2
URL:            http://openshift.redhat.com
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

Requires:       selinux-policy selinux-policy-targeted
Requires:       policycoreutils-python

%description
Stickshfit SELinux policies from the master_contrib branch of
selinux-policy at commit c2f865d.

git://git.fedorahosted.org/selinux-policy.git

%prep
%setup -q


%build
make -f /usr/share/selinux/devel/Makefile
bzip2 openshift.pp openshift-origin.pp

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p %{buildroot}%{_datadir}/selinux/packages/%{name}
mkdir -p %{buildroot}%{_datadir}/selinux/devel/include/services

install -m 644 *.pp.bz2        %{buildroot}%{_datadir}/selinux/packages/%{name}
install -m 644 *.if            %{buildroot}%{_datadir}/selinux/devel/include/services

%post
semodule -i %{_datadir}/selinux/packages/%{name}/*.pp.bz2
touch /.autorelabel

%files
%defattr(-,root,root,-)
%doc COPYING README
%{_datadir}/selinux/packages/%{name}/
%{_datadir}/selinux/devel/include/services/*.if

%changelog
* Mon Oct 01 2012 Rob Millner <rmillner@redhat.com> 1.0.1-1
- Updated to openshift 1.0 policies


* Fri Sep 28 2012 Rob Millner <rmillner@redhat.com> 0.1.1-1
- Move stickshift selinux policies into their own RPM.

