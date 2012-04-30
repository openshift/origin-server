%global cartridgedir %{_libexecdir}/stickshift/cartridges/embedded/mysql-5.1
%global frameworkdir %{_libexecdir}/stickshift/cartridges/mysql-5.1

Name: cartridge-mysql-5.1
Version: 0.26.1
Release: 1%{?dist}
Summary: Provides embedded mysql support

Group: Network/Daemons
License: ASL 2.0
URL: http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/crankcase/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: git
Requires: stickshift-abstract
Requires: mysql-server
Requires: mysql-devel


%description
Provides mysql cartridge support to OpenShift


%prep
%setup -q


%build
rm -rf git_template
cp -r template/ git_template/
cd git_template
git config --global user.email "builder@example.com"
git config --global user.name "Template builder"
git init
git add -f .
git commit -m 'Creating template'
cd ..
git clone --bare git_template git_template.git
rm -rf git_template
touch git_template.git/refs/heads/.gitignore


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/data/
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r info %{buildroot}%{cartridgedir}/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
ln -s %{cartridgedir} %{buildroot}/%{frameworkdir}
ln -s %{cartridgedir}/../../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%config(noreplace) %{cartridgedir}/info/configuration/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/lib/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0755,-,-) %{frameworkdir}
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.26.1-1
- bumping spec versions (admiller@redhat.com)

* Tue Apr 24 2012 Adam Miller <admiller@redhat.com> 0.25.7-1
- Crankcase missing node_ssl_template.conf - add it in - fix for bugz 815276.
  (ramr@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.25.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.25.5-1
- new package built with tito
