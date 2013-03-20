%global cartridgedir %{_libexecdir}/openshift/cartridges/ceylon-0.5

Summary:   Provides ceylon-0.5 support
Name:      openshift-origin-cartridge-ceylon-0.5
Version:   1.0.22
Release:   1%{?dist}
Group:     Development/Languages
License:   ASL 2.0
URL:       http://openshift.redhat.com
Source0: http://mirror.openshift.com/pub/origin-server/source/%{name}/%{name}-%{version}.tar.gz


BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: git
Requires: java-1.7.0-openjdk
Requires: ceylon >= 0.5
Requires: ceylon
Requires: openshift-origin-cartridge-abstract
Requires: rubygem(openshift-origin-node)
Requires: mod_bw
Requires: rubygem-builder

%description
Provides ceylon support to OpenShift

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
mkdir -p %{buildroot}/%{_sysconfdir}/openshift/cartridges
ln -s %{cartridgedir}/info/configuration/ %{buildroot}/%{_sysconfdir}/openshift/cartridges/%{name}
cp -r info %{buildroot}%{cartridgedir}/
cp LICENSE %{buildroot}%{cartridgedir}/
cp COPYRIGHT %{buildroot}%{cartridgedir}/
mkdir -p %{buildroot}%{cartridgedir}/info/data/
cp -r git_template.git %{buildroot}%{cartridgedir}/info/data/
ln -s %{cartridgedir}/../abstract/info/hooks/add-module %{buildroot}%{cartridgedir}/info/hooks/add-module
ln -s %{cartridgedir}/../abstract/info/hooks/info %{buildroot}%{cartridgedir}/info/hooks/info
ln -s %{cartridgedir}/../abstract/info/hooks/reload %{buildroot}%{cartridgedir}/info/hooks/reload
ln -s %{cartridgedir}/../abstract/info/hooks/remove-module %{buildroot}%{cartridgedir}/info/hooks/remove-module
ln -s %{cartridgedir}/../abstract/info/hooks/restart %{buildroot}%{cartridgedir}/info/hooks/restart
ln -s %{cartridgedir}/../abstract/info/hooks/start %{buildroot}%{cartridgedir}/info/hooks/start
ln -s %{cartridgedir}/../abstract-httpd/info/hooks/status %{buildroot}%{cartridgedir}/info/hooks/status
ln -s %{cartridgedir}/../abstract/info/hooks/stop %{buildroot}%{cartridgedir}/info/hooks/stop
ln -s %{cartridgedir}/../abstract/info/hooks/update-namespace %{buildroot}%{cartridgedir}/info/hooks/update-namespace
ln -s %{cartridgedir}/../abstract/info/hooks/deploy-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/deploy-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/remove-httpd-proxy %{buildroot}%{cartridgedir}/info/hooks/remove-httpd-proxy
ln -s %{cartridgedir}/../abstract/info/hooks/tidy %{buildroot}%{cartridgedir}/info/hooks/tidy
ln -s %{cartridgedir}/../abstract/info/hooks/move %{buildroot}%{cartridgedir}/info/hooks/move
ln -s %{cartridgedir}/../abstract/info/hooks/threaddump %{buildroot}%{cartridgedir}/info/hooks/threaddump
ln -s %{cartridgedir}/../abstract/info/hooks/system-messages %{buildroot}%{cartridgedir}/info/hooks/system-messages
mkdir -p %{buildroot}%{cartridgedir}/info/connection-hooks/
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-gear-endpoint %{buildroot}%{cartridgedir}/info/connection-hooks/publish-gear-endpoint
ln -s %{cartridgedir}/../abstract/info/connection-hooks/publish-http-url %{buildroot}%{cartridgedir}/info/connection-hooks/publish-http-url
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-db-connection-info
ln -s %{cartridgedir}/../abstract/info/connection-hooks/set-nosql-db-connection-info %{buildroot}%{cartridgedir}/info/connection-hooks/set-nosql-db-connection-info
ln -s %{cartridgedir}/../abstract/info/bin/sync_gears.sh %{buildroot}%{cartridgedir}/info/bin/sync_gears.sh

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%attr(0755,-,-) %{cartridgedir}/info/hooks
%attr(0750,-,-) %{cartridgedir}/info/hooks/*
%attr(0755,-,-) %{cartridgedir}/info/hooks/tidy
%attr(0750,-,-) %{cartridgedir}/info/data/
%attr(0750,-,-) %{cartridgedir}/info/build/
%attr(0755,-,-) %{cartridgedir}/info/bin/
%attr(0755,-,-) %{cartridgedir}/info/connection-hooks/
%config(noreplace) %{cartridgedir}/info/configuration/
%{_sysconfdir}/openshift/cartridges/%{name}
%{cartridgedir}/info/changelog
%{cartridgedir}/info/control
%{cartridgedir}/info/manifest.yml
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
* Wed Mar 20 2013 Matej Lazar <matejonnet@gmail.com> 1.0.22-1
- Removed modules preset in Herd. (matejonnet@gmail.com)
- Welcome page & sample app. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.21-1]. (matejonnet@gmail.com)
- Static files location. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.20-1]. (matejonnet@gmail.com)
- Remove missing function. (matejonnet@gmail.com)
- Build in cofigure hook. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.19-1]. (matejonnet@gmail.com)
- Remove SDK modules. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.18-1]. (matejonnet@gmail.com)
- Demo app update. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.17-1]. (matejonnet@gmail.com)
- User hooks. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.16-1]. (matejonnet@gmail.com)
- Remove idx from modules. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.15-1]. (matejonnet@gmail.com)
- Inclue ceylon sdk. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.14-1]. (matejonnet@gmail.com)
- jenkins build (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.13-1]. (matejonnet@gmail.com)
- Jenkins template. (matejonnet@gmail.com)
- Start, Stop, ReStart fixed. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.12-1]. (matejonnet@gmail.com)
- Update start stop. (matejonnet@gmail.com)
- Update start stop. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.11-1]. (matejonnet@gmail.com)
- Update paths. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.10-1]. (matejonnet@gmail.com)
- Template fix. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.9-1]. (matejonnet@gmail.com)
- Lounch app. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.8-1]. (matejonnet@gmail.com)
- Cartridge scripts update. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.7-1]. (matejonnet@gmail.com)
- remove php (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.6-1]. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.5-1]. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.4-1]. (matejonnet@gmail.com)
- Description update. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.3-1]. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.2-1]. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.1-1]. (matej@broker.example.com)
- Ceylon cartridge. (root@broker.example.com)

* Mon Mar 18 2013 Matej Lazar <matejonnet@gmail.com> 1.0.21-1
- Static files location. (matejonnet@gmail.com)

* Mon Mar 18 2013 Matej Lazar <matejonnet@gmail.com> 1.0.20-1
- Remove missing function. (matejonnet@gmail.com)
- Build in cofigure hook. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.19-1]. (matejonnet@gmail.com)
- Remove SDK modules. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.18-1]. (matejonnet@gmail.com)
- Demo app update. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.17-1]. (matejonnet@gmail.com)
- User hooks. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.16-1]. (matejonnet@gmail.com)
- Remove idx from modules. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.15-1]. (matejonnet@gmail.com)
- Inclue ceylon sdk. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.14-1]. (matejonnet@gmail.com)
- jenkins build (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.13-1]. (matejonnet@gmail.com)
- Jenkins template. (matejonnet@gmail.com)
- Start, Stop, ReStart fixed. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.12-1]. (matejonnet@gmail.com)
- Update start stop. (matejonnet@gmail.com)
- Update start stop. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.11-1]. (matejonnet@gmail.com)
- Update paths. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.10-1]. (matejonnet@gmail.com)
- Template fix. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.9-1]. (matejonnet@gmail.com)
- Lounch app. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.8-1]. (matejonnet@gmail.com)
- Cartridge scripts update. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.7-1]. (matejonnet@gmail.com)
- remove php (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.6-1]. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.5-1]. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.4-1]. (matejonnet@gmail.com)
- Description update. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.3-1]. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.2-1]. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.1-1]. (matej@broker.example.com)
- Ceylon cartridge. (root@broker.example.com)

* Sun Mar 17 2013 Matej Lazar <matejonnet@gmail.com> 1.0.19-1
- Remove SDK modules. (matejonnet@gmail.com)

* Sun Mar 17 2013 Matej Lazar <matejonnet@gmail.com> 1.0.18-1
- Demo app update. (matejonnet@gmail.com)

* Sun Feb 10 2013 Matej Lazar <matejonnet@gmail.com> 1.0.17-1
- User hooks. (matejonnet@gmail.com)

* Sat Feb 09 2013 Matej Lazar <matejonnet@gmail.com> 1.0.16-1
- Remove idx from modules. (matejonnet@gmail.com)

* Sat Feb 09 2013 Matej Lazar <matejonnet@gmail.com> 1.0.15-1
- Inclue ceylon sdk. (matejonnet@gmail.com)

* Sat Feb 09 2013 Matej Lazar <matejonnet@gmail.com> 1.0.14-1
- jenkins build (matejonnet@gmail.com)

* Wed Feb 06 2013 Matej Lazar <matejonnet@gmail.com> 1.0.13-1
- Jenkins template. (matejonnet@gmail.com)
- Start, Stop, ReStart fixed. (matejonnet@gmail.com)

* Wed Feb 06 2013 Matej Lazar <matejonnet@gmail.com> 1.0.12-1
- Update start stop. (matejonnet@gmail.com)
- Update start stop. (matejonnet@gmail.com)

* Wed Feb 06 2013 Matej Lazar <matejonnet@gmail.com> 1.0.11-1
- Update paths. (matejonnet@gmail.com)

* Tue Feb 05 2013 Matej Lazar <matejonnet@gmail.com> 1.0.10-1
- Template fix. (matejonnet@gmail.com)

* Tue Feb 05 2013 Matej Lazar <matejonnet@gmail.com> 1.0.9-1
- Lounch app. (matejonnet@gmail.com)

* Mon Feb 04 2013 Matej Lazar <matejonnet@gmail.com> 1.0.8-1
- Cartridge scripts update. (matejonnet@gmail.com)

* Wed Jan 30 2013 Matej Lazar <matejonnet@gmail.com> 1.0.7-1
- remove php (matejonnet@gmail.com)

* Wed Jan 30 2013 Matej Lazar <matejonnet@gmail.com> 1.0.6-1
- 

* Wed Jan 30 2013 Matej Lazar <matejonnet@gmail.com> 1.0.5-1
- 

* Tue Jan 29 2013 Matej Lazar <matejonnet@gmail.com> 1.0.4-1
- Description update. (matejonnet@gmail.com)

* Tue Jan 29 2013 Matej Lazar <matejonnet@gmail.com> 1.0.3-1
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.2-1]. (matejonnet@gmail.com)
- Automatic commit of package [openshift-origin-cartridge-ceylon-0.5] release
  [1.0.1-1]. (matej@broker.example.com)
- Ceylon cartridge. (root@broker.example.com)

* Mon Jan 28 2013 Matej Lazar <matejonnet@gmail.com> 1.0.2-1
- 

* Mon Jan 28 2013 Unknown name 1.0.1-1
- new package built with tito

* Wed Jan 23 2013 Adam Miller <mlazar@redhat.com> 1.0.0-1
- new cartridge (mlazar@redhat.com)
