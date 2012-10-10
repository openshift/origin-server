Name:           openshift-origin-selinux
Version:        1.0.7
Release:        1%{?dist}
Summary:        Openshift Origin SELinux policies

License:        GPLv2
URL:            http://openshift.redhat.com
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch

Requires:       selinux-policy selinux-policy-targeted
Requires:       policycoreutils-python

%description
Openshift Origin SELinux policies from the master_contrib and master
branches of selinux-policy at commit c2f865d.

git://git.fedorahosted.org/selinux-policy.git

%prep
%setup -q


%build
for sfx in fc if te
do
    if [ -f "openshift-backport%{dist}.${sfx}.disabled" ]
    then
        rm -f "openshift-backport.${sfx}"
        ln -sf "openshift-backport%{dist}.${sfx}.disabled" "openshift-backport.${sfx}"
    fi
done

make -f /usr/share/selinux/devel/Makefile
bzip2 *.pp

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p %{buildroot}%{_datadir}/selinux/packages
mkdir -p %{buildroot}%{_datadir}/selinux/devel/include/services

install -m 644 *.pp.bz2        %{buildroot}%{_datadir}/selinux/packages
install -m 644 *.if            %{buildroot}%{_datadir}/selinux/devel/include/services

%pre
# Not compatible with the old libra policy and its RPM doesn't provide
# for removal
semodule -r libra || :

%post
semodule -i \
    %{_datadir}/selinux/packages/openshift.pp.bz2 \
    %{_datadir}/selinux/packages/openshift-origin.pp.bz2 \
    %{_datadir}/selinux/packages/openshift-support.pp.bz2 \
    %{_datadir}/selinux/packages/openshift-backport.pp.bz2


%preun
if [ $1 = 0 ]
then
    semodule -r \
        %{_datadir}/selinux/packages/openshift.pp.bz2 \
        %{_datadir}/selinux/packages/openshift-origin.pp.bz2 \
        %{_datadir}/selinux/packages/openshift-support.pp.bz2 \
        %{_datadir}/selinux/packages/openshift-backport.pp.bz2
fi

%files
%defattr(-,root,root,-)
%doc COPYING README
%{_datadir}/selinux/packages/*.pp.bz2
%{_datadir}/selinux/devel/include/services/*.if

%changelog
* Wed Oct 10 2012 Rob Millner <rmillner@redhat.com> 1.0.7-1
- Automatic commit of package [openshift-origin-selinux] release [1.0.6-1].
  (rmillner@redhat.com)
- Move SELinux to Origin and use new policy definition. Include backport
  selinux package. (rmillner@redhat.com)

* Wed Oct 10 2012 Rob Millner <rmillner@redhat.com> 1.0.6-1
- Move SELinux to Origin and use new policy definition. Include backport
  selinux package. (rmillner@redhat.com)

* Wed Oct 10 2012 Rob Millner <rmillner@redhat.com> 1.0.5-1
- Use the same names as the newer selinux-policy package which replaces this.
- Add a dummy backport policy module so there's always one in the RPM.


* Fri Oct 05 2012 Rob Millner <rmillner@redhat.com> 1.0.4-1
- Rename to origin-server-selinux

* Fri Oct 05 2012 Rob Millner <rmillner@redhat.com> 1.0.3-1
- The dist macro uses fc rather than just f. (rmillner@redhat.com)
- Use openshift-backport policy instead (rmillner@redhat.com)
- Add Fedora 17 and 16 policy support and mechanism to select them on build.
  (rmillner@redhat.com)
- Update description (rmillner@redhat.com)
- Back-ported build requirements from Fedora 17 (rmillner@redhat.com)
- Add preun and dont touch autorelabel. (rmillner@redhat.com)

* Fri Oct 05 2012 Rob Millner <rmillner@redhat.com> 1.0.2-1
- Create new openshift-support module to carry Openshift related policies from
  other modules. (rmillner@redhat.com)
- Update SELinux policies to commit c2f865d (rmillner@redhat.com)
- Fix license for selinux (rmillner@redhat.com)
- Force relabel on next reboot after pkg install. (rmillner@redhat.com)
- Clean up selinux specfile (rmillner@redhat.com)
- Automatic commit of package [stickshift-selinux] release [1.0.1-1].
  (rmillner@redhat.com)
- Switch to openshift policies. (rmillner@redhat.com)
- Move policy build to the build phase and do installation in %%post
  (rmillner@redhat.com)


* Mon Oct 01 2012 Rob Millner <rmillner@redhat.com> 1.0.1-1
- Updated to openshift 1.0 policies


* Fri Sep 28 2012 Rob Millner <rmillner@redhat.com> 0.1.1-1
- Move stickshift selinux policies into their own RPM.

