Name:     tuned-profiles-openshift-node
Version: 0.2.1
Release:  1%{?dist}
Summary:  tuned profile for openshift node hosts

Group:    Development/System
License:  ASL 2.0
URL:      https://openshift.com
Source0:  %{name}-%{version}.tar.gz

Requires: tuned

%description
A tuned profile customized for OpenShift Node host roles.

%prep
%setup -q


%build

%install
mkdir -p %{buildroot}/etc/tune-profiles/openshift-node/
cp -r profile/* %{buildroot}/etc/tune-profiles/openshift-node/


%files
/etc/tune-profiles/openshift-node/ktune.sh
/etc/tune-profiles/openshift-node/ktune.sysconfig
/etc/tune-profiles/openshift-node/sysctl.ktune
/etc/tune-profiles/openshift-node/tuned.conf

%post
/usr/sbin/tuned-adm profile openshift-node > /dev/null 2>&1

%preun
# reset the tuned profile to the recommended profile
# $1 = 0 when we're being removed > 0 during upgrades
if [ "$1" = 0 ]; then
  /usr/sbin/tuned-adm profile default > /dev/null 2>&1
fi

%changelog
* Thu Mar 19 2015 Adam Miller <admiller@redhat.com> 0.2.1-1
- bump_minor_versions for sprint 60 (admiller@redhat.com)

* Thu Feb 12 2015 Adam Miller <admiller@redhat.com> 0.1.2-1
- Only reset the profile when being uninstalled (sdodson@redhat.com)
- BZ889539 - Fix profile removal (sdodson@redhat.com)
- Don't load /etc/sysctl.ktune (sdodson@redhat.com)

* Wed Jan 07 2015 Adam Miller <admiller@redhat.com> 0.1.1-1
- new package built with tito

* Mon Jan 05 2015 Scott Dodson <sdodson@redhat.com> 0.1.0-1
- new package built with tito

* Mon Jan 05 2015 Scott Dodson <sdodson@redhat.com> - 0.1-1
- Initial packaging
