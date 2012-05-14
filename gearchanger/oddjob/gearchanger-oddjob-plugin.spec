%global ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%global gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%global gemname gearchanger-oddjob-plugin
%global geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary:        GearChanger plugin for oddjob service
Name:           rubygem-%{gemname}
Version:        0.8.5
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            http://openshift.redhat.com
Source0:        rubygem-%{gemname}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       ruby(abi) = 1.8
Requires:       rubygems
Requires:       oddjob
Requires:       rubygem(stickshift-common)
Requires:       stickshift-broker
Requires:       rubygem(json)
Requires:  		selinux-policy-targeted
Requires:  		policycoreutils-python

BuildRequires:  ruby
BuildRequires:  rubygems
BuildArch:      noarch
Provides:       rubygem(%{gemname}) = %version

%package -n ruby-%{gemname}
Summary:        GearChanger plugin for oddjob based node/gear manager
Requires:       rubygem(%{gemname}) = %version
Provides:       ruby(%{gemname}) = %version

%description
GearChanger plugin for oddjob based node/gear manager

%description -n ruby-%{gemname}
GearChanger plugin for oddjob based node/gear manager

%prep
%setup -q

%clean
rm -rf %{buildroot}                                

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
mkdir -p %{buildroot}%{ruby_sitelib}

# Build and install into the rubygem structure
gem build %{gemname}.gemspec
gem install --local --install-dir %{buildroot}%{gemdir} --force %{gemname}-%{version}.gem

# Symlink into the ruby site library directories
ln -s %{geminstdir}/lib/%{gemname} %{buildroot}%{ruby_sitelib}
ln -s %{geminstdir}/lib/%{gemname}.rb %{buildroot}%{ruby_sitelib}

# move the selinux policy files into proper location
mkdir -p %{buildroot}/usr/share/selinux/packages/rubygem-%{gemname}
cp %{buildroot}%{geminstdir}/docs/examples/selinux/* %{buildroot}/usr/share/selinux/packages/rubygem-%{gemname}/

# move dbus/oddjob config files
mkdir -p %{buildroot}%{_sysconfdir}/dbus-1/system.d/
mkdir -p %{buildroot}%{_sysconfdir}/oddjobd.conf.d/
cp %{buildroot}%{geminstdir}/docs/examples/stickshift-dbus.conf %{buildroot}%{_sysconfdir}/dbus-1/system.d/
cp %{buildroot}%{geminstdir}/docs/examples/oddjobd-ss-exec.conf %{buildroot}%{_sysconfdir}/oddjobd.conf.d/

# Move the gem binaries to the standard filesystem location
mkdir -p %{buildroot}%{_bindir}
mv %{buildroot}%{gemdir}/bin/* %{buildroot}%{_bindir}
rm -rf %{buildroot}%{gemdir}/bin

%post
pushd /usr/share/selinux/packages/rubygem-%{gemname}/
make -f /usr/share/selinux/devel/Makefile
popd
/usr/sbin/semodule -i /usr/share/selinux/packages/rubygem-%{gemname}/gearchanger-oddjob.pp
/usr/sbin/semanage fcontext -a -e /home /var/lib/stickshift
/sbin/restorecon -R /var/lib/stickshift /usr/bin/ss-exec-command || :

%postun
/usr/sbin/semodule -r gearchanger-oddjob
/usr/sbin/semanage fcontext -d /var/lib/stickshift
/sbin/restorecon -R /var/lib/stickshift /usr/bin/ss-exec-command || :

%files
%defattr(-,root,root,-)
%dir %{geminstdir}
%doc %{geminstdir}/Gemfile
%{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/gems/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%config(noreplace) %{_sysconfdir}/oddjobd.conf.d/oddjobd-ss-exec.conf
%config(noreplace) %{_sysconfdir}/dbus-1/system.d/stickshift-dbus.conf
%attr(0700,-,-) %{_bindir}/ss-exec-command
/usr/share/selinux/packages/rubygem-%{gemname}

%files -n ruby-%{gemname}
%{ruby_sitelib}/%{gemname}
%{ruby_sitelib}/%{gemname}.rb

%changelog
* Mon May 14 2012 Krishna Raman <kraman@gmail.com> 0.8.5-1
- Adding livecd build scripts (kraman@gmail.com)
- Update gear dns entried when app namespace is updated (kraman@gmail.com)
- adding gear state to gear_groups rest api (abhgupta@redhat.com)
- BugZ 817170. Add ability to get valid gear size options from the
  ApplicationContainerProxy (kraman@gmail.com)

* Wed Apr 25 2012 Krishna Raman <kraman@gmail.com> 0.8.4-1
- Update oddjob plugin dependencies to include oddjob (kraman@gmail.com)
- Merge branch 'master' of github.com:openshift/crankcase (rpenta@redhat.com)
- Fix update namespace for scalable apps (rpenta@redhat.com)
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Krishna Raman <kraman@gmail.com> 0.8.3-1
- new package built with tito

