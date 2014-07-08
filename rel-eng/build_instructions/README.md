#How to build OpenShift Origin from Source

## Using RHEL or CentOS 6

### Setting up your machine for building
#### 1. We need to have EPEL6 installed
``` 
yum -y install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
```

#### 2. OpenShift Origin Dependency Repo setup

If you're building from Master, you'll need the nighly dependency repos.
```
cat > /etc/yum.repos.d/openshift-origin-nightly-deps.repo <<EOF
[openshift-origin-nightly-deps]
name=openshift-origin-nightly-deps
baseurl=https://mirror.openshift.com/pub/origin-server/nightly/rhel-6/dependencies/x86_64/
enabled=1
gpgcheck=0
skip_if_unavailable=1
EOF
```

  If you're building from Release v4, you'll need the v4 dependency repos.
```
cat > /etc/yum.repos.d/openshift-origin-v4-deps.repo <<EOF
[openshift-origin-v4-deps]
name=openshift-origin-v4-deps
baseurl=http://mirror.openshift.com/pub/origin-server/release/4/rhel-6/dependencies/x86_64/
enabled=1
gpgcheck=0
skip_if_unavailable=1
EOF
```

Alternatively you can find both these .repo files in this directory of the git repository.

#### 3. Need to install the pre-requisite packages required to build.

```
yum -y install @fedora-packager ruby193-ruby-devel ruby193-rubygems-devel scl-utils-build tito git
```

#### 4. Need to add custom mock configs to be able to build with [Software Collections](https://www.softwarecollections.org/en/)

Copy both (or the desired build target: nightly or v4) from the current directory in git to `/etc/mock/` on your build machine.

```
cp ./epel-6-x86_64-openshift-* /etc/mock
```

#### 5. Need to setup an user for mock

```
useradd user 
usermod -a -G mock user 
# logout or launch new login shell 'bash -'
```

#### 6. Clone the repo (pending you haven't already)

```
git clone https://github.com/openshift/origin-server.git
```

#### 7. Build!

If you want to build a specific package, you can navigate to the directory where that package's .spec file lives and then perform a mock build there.

For OpenShift V4 builds, use the following command:
```
cd origin-server/common/
tito build --builder mock --arg mock=epel-6-x86_64-openshiftv4 --rpm
```

For OpenShift Nightly builds, use the following command:
```
cd origin-server/common/
tito build --builder mock --arg mock=epel-6-x86_64-openshift-nightly --rpm --test
# NOTE: The '--test' here is to build off latest git commit
#       and not from specific git tag, this is needed for 
#       nightly builds as well as the mock config.
```

However, if we would like to build the entire package set this can be scripted out (somewhat crudely) as follows:

For OpenShift V4 builds, use the following commands:
```
mkdir /var/tmp/completed_builds/
declare -a failed_builds
spec_dirs=( $(find origin-server/ -name \*.spec) )
for spec in ${spec_dirs[@]}
do
  pushd $(dirname $spec)
    tito build --builder mock --arg mock=epel-6-x86_64-openshiftv4 --rpm 
    if [[ $? -ne "0"]]; then
      failed_builds+=( "$spec" )
    else
      mv /var/lib/mock/epel-6-x86_64/*.rpm /var/tmp/completed_builds/
    fi
  popd
done
if [[ ${#failed_builds[@]} -ne "0" ]]; then
  echo "Failed builds: ${failed_builds[@]}"
fi
```
At the end of this build task, you should have all the rpms and srpms in /var/tmp/completed_builds/ and we can now create a yum repository out of it with the `createrepo` or use them how ever you please.

## Using Fedora 
`#FIXME - add content here later`
