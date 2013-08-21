%global cartridgedir %{_libexecdir}/openshift/cartridges/nodejs

Summary:       Provides Node.js support
Name:          openshift-origin-cartridge-nodejs
Version: 1.14.4
Release:       1%{?dist}
Group:         Development/Languages
License:       ASL 2.0
URL:           http://www.openshift.com
Source0:       http://mirror.openshift.com/pub/openshift-origin/source/%{name}/%{name}-%{version}.tar.gz
BuildRequires: nodejs >= 0.6
Requires:      facter
Requires:      rubygem(openshift-origin-node)
Requires:      openshift-origin-node-util
Requires:      nodejs-async
Requires:      nodejs-connect
Requires:      nodejs-express
Requires:      nodejs-mongodb
Requires:      nodejs-mysql
Requires:      nodejs-node-static
Requires:      nodejs-pg
Requires:      nodejs-supervisor
Requires:      nodejs-options
%if 0%{?fedora} >= 19
Requires:      npm
%endif

Obsoletes: openshift-origin-cartridge-nodejs-0.6

BuildArch:     noarch

%description
Provides Node.js support to OpenShift. (Cartridge Format V2)

%prep
%setup -q

%build
%__rm %{name}.spec

%install
%__mkdir -p %{buildroot}%{cartridgedir}
%__cp -r * %{buildroot}%{cartridgedir}

if [ -f /usr/local/3n/versions/*/bin/node ]; then
    echo "USING NPM VERSION ON SERVER"
    export PATH=$/usr/local/n/versions/*/bin:$PATH
else		   
     echo "USING NODE VERSION ON SERVER"	
fi
 
if [[ $(node -v) == v0.6* ]]; then
    %__rm -rf %{buildroot}%{cartridgedir}/versions/0.10
	%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.6 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
fi
if [[ $(node -v) == v0.10* ]]; then
    %__rm -rf %{buildroot}%{cartridgedir}/versions/0.6
	%__mv %{buildroot}%{cartridgedir}/metadata/manifest.yml.0.10 %{buildroot}%{cartridgedir}/metadata/manifest.yml;
fi

%files
%dir %{cartridgedir}
%attr(0755,-,-) %{cartridgedir}/bin/
%attr(0755,-,-) %{cartridgedir}/hooks/
%{cartridgedir}
%doc %{cartridgedir}/README.md
%doc %{cartridgedir}/COPYRIGHT
%doc %{cartridgedir}/LICENSE

%changelog
