%global cartridgedir %{_libexecdir}/stickshift/cartridges/diy-0.1

Summary:   Provides diy support
Name:      cartridge-diy-0.1
Version:   0.26.2
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/crankcase/source/%{name}/%{name}-%{version}.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: git

Requires: stickshift-abstract
Requires: rubygem(stickshift-node)
Requires: httpd


%description
Provides diy support to OpenShift


%prep
%setup -q


%build
rm -rf git_template
cp -r template/ git_template/
cd git_template
git init
git add -f .
git config user.email "builder@example.com"
git config user.name "Template builder"
git commit -m 'Creating template'
cd ..
git clone --bare git_template git_template.git
rm -rf git_template
touch git_template.git/refs/heads/.gitignore


%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{cartridgedir}
mkdir -p %{buildroot}%{cartridgedir}/info/data/
mkdir -p %{buildroot}%{cartridgedir}/info/connection-hooks/
mkdir -p %{buildroot}/%{_sysconfdir}/stickshift/cartridges
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/stickshift/cartridges/%{name}
ln -s %{cartridgedir}/../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../abstract/info/hooks/post-install %{buildroot}%{cartridgedir}/info/hooks/post-install
ln -s %{cartridgedir}/../abstract/info/hooks/post-remove %{buildroot}%{cartridgedir}/info/hooks/post-remove
ln -s %{cartridgedir}/../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../abstract/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/preconfigure %{buildroot}%{cartridgedir}/info/hooks/preconfigure
ln -s %{cartridgedir}/../abstract/info/hooks/force-stop %{buildroot}%{cartridgedir}/info/hooks/force-stop
ln -s %{cartridgedir}/../abstract/info/hooks/add-alias %{buildroot}%{cartridgedir}/info/hooks/add-alias
ln -s %{cartridgedir}/../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-alias %{buildroot}%{cartridgedir}/info/hooks/remove-alias
ln -s %{cartridgedir}/../abstract/info/hooks/move %{buildroot}%{cartridgedir}/info/hooks/move
ln -s %{cartridgedir}/../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../abstract/info/hooks/expose-port %{buildroot}%{cartridgedir}/info/hooks/expose-port
ln -s %{cartridgedir}/../abstract/info/hooks/conceal-port %{buildroot}%{cartridgedir}/info/hooks/conceal-port
ln -s %{cartridgedir}/../abstract/info/hooks/show-port %{buildroot}%{cartridgedir}/info/hooks/show-port
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-gear-endpoint %{buildroot}%{cartridgedir}/info/connection-hooks/publish-gear-endpoint
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-http-url %{buildroot}%{cartridgedir}/info/connection-hooks/publish-http-url
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
ln -s %{cartridgedir}/../abstract/info/bin/sync_gears.sh %{buildroot}%{cartridgedir}/info/bin/sync_gears.sh


%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%attr(0750,-,-) %{cartridgedir}/info/hooks/
%attr(0750,-,-) %{cartridgedir}/info/connection-hooks/
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/stickshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE


%changelog
* Mon May 07 2012 Adam Miller <admiller@redhat.com> 0.26.2-1
- remove old obsoletes (dmcphers@redhat.com)
- clean specs (whearn@redhat.com)

* Thu Apr 26 2012 Adam Miller <admiller@redhat.com> 0.26.1-1
- bumping spec versions (admiller@redhat.com)

* Mon Apr 23 2012 Adam Miller <admiller@redhat.com> 0.25.6-1
- cleaning up spec files (dmcphers@redhat.com)

* Sat Apr 21 2012 Dan McPherson <dmcphers@redhat.com> 0.25.5-1
- new package built with tito
