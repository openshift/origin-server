%if 0%{?fedora}%{?rhel} <= 6
    %global scl ruby193
    %global scl_prefix ruby193-
%endif
%{!?scl:%global pkg_name %{name}}
%{?scl:%scl_package rubygem-%{gem_name}}
%global gem_name openshift-origin-console
%global rubyabi 1.9.1

Summary:        OpenShift Origin Management Console
Name:           rubygem-%{gem_name}
Version:        0.0.2
Release:        1%{?dist}
Group:          Development/Languages
License:        ASL 2.0
URL:            https://openshift.redhat.com
Source0:        rubygem-%{gem_name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
Requires:       %{?scl:%scl_prefix}ruby
Requires:       %{?scl:%scl_prefix}rubygems
Requires:       %{?scl:%scl_prefix}rubygem(rails)
Requires:       %{?scl:%scl_prefix}rubygem(compass-rails)
Requires:       %{?scl:%scl_prefix}rubygem(rdiscount)
Requires:       %{?scl:%scl_prefix}rubygem(formtastic)
Requires:       %{?scl:%scl_prefix}rubygem(net-http-persistent)
Requires:       %{?scl:%scl_prefix}rubygem(haml)

%if 0%{?fedora}%{?rhel} <= 6
BuildRequires:  ruby193-build
BuildRequires:  scl-utils-build
%endif

BuildRequires:  %{?scl:%scl_prefix}ruby(abi) = %{rubyabi}
BuildRequires:  %{?scl:%scl_prefix}ruby 
BuildRequires:  %{?scl:%scl_prefix}rubygems
BuildRequires:  %{?scl:%scl_prefix}rubygems-devel
BuildRequires:  %{?scl:%scl_prefix}rubygem(rails)
BuildRequires:  %{?scl:%scl_prefix}rubygem(compass-rails)
BuildRequires:  %{?scl:%scl_prefix}rubygem(mocha)
BuildRequires:  %{?scl:%scl_prefix}rubygem(simplecov)
BuildRequires:  %{?scl:%scl_prefix}rubygem(test-unit)
BuildRequires:  %{?scl:%scl_prefix}rubygem(ci_reporter)
BuildRequires:  %{?scl:%scl_prefix}rubygem(webmock)
BuildRequires:  %{?scl:%scl_prefix}rubygem(sprockets)
BuildRequires:  %{?scl:%scl_prefix}rubygem(rdiscount)
BuildRequires:  %{?scl:%scl_prefix}rubygem(formtastic)
BuildRequires:  %{?scl:%scl_prefix}rubygem(net-http-persistent)
BuildRequires:  %{?scl:%scl_prefix}rubygem(haml)
BuildRequires:  %{?scl:%scl_prefix}rubygem(therubyracer)

BuildArch:      noarch
Provides:       rubygem(%{gem_name}) = %version
%description
This contains the OpenShift Origin Management Console.

%package doc
Summary: OpenShift Origin Management Console docs.

%description doc
OpenShift Origin Management Console ri documentation 

%prep
%setup -q

%build
%{?scl:scl enable %scl - << \EOF}
mkdir -p .%{gem_dir}

# Temporary BEGIN
rm Gemfile.lock
bundle install --local
# Temporary END
pushd test/rails_app/
RAILS_ENV=production RAILS_RELATIVE_URL_ROOT=/console bundle exec rake assets:precompile assets:public_pages
rm -rf tmp/cache/*
echo > log/production.log
popd

# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        %{gem_name}-%{version}.gem
%{?scl:EOF}

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

%clean
rm -rf %{buildroot}

%files
%doc %{gem_instdir}/Gemfile
%doc %{gem_instdir}/LICENSE 
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/COPYRIGHT
%{gem_instdir}
%{gem_cache}
%{gem_spec}

%files doc
%{gem_dir}/doc/%{gem_name}-%{version}

%changelog
* Fri Sep 28 2012 Adam Miller <admiller@redhat.com> 0.0.2-1
- Merge pull request #546 from smarterclayton/bug861317_typo_in_error
  (openshift+bot@redhat.com)
- Add instructions on finding a JS runtime (ccoleman@redhat.com)
- Bug 861317 - Typo in key error page (ccoleman@redhat.com)
- Merge pull request #542 from smarterclayton/remove_execjs_dependency
  (openshift+bot@redhat.com)
- Merge pull request #541 from smarterclayton/stack_overflow_link_broken
  (openshift+bot@redhat.com)
- ExecJS no longer needs spidermonkey with httpd_execmem selinux permission set
  (ccoleman@redhat.com)
- StackOverflow link was broken in console (ccoleman@redhat.com)
- Merge pull request #539 from
  smarterclayton/bug821107_pass_all_key_types_to_broker
  (openshift+bot@redhat.com)
- Merge pull request #537 from
  smarterclayton/bug860969_remove_deep_user_guide_link
  (openshift+bot@redhat.com)
- Bug 821107 - Allow all key types potentially (ccoleman@redhat.com)
- Bug 860969 - Remove user guide deep link (ccoleman@redhat.com)
- Simplify the console proxy setup to support native ENV from
  net::http::persistent (ccoleman@redhat.com)

* Wed Sep 26 2012 Clayton Coleman <ccoleman@redhat.com> 0.0.1-1
- Initial commit of OpenShift Origin console

