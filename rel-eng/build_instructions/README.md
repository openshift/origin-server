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

However, if we would like to build the entire package set this has been scripted out using the build_openshift_origin.sh script in this directory:

This command should be run from the "root" of your local origin-server git clone.

For general usage of the script:
```
./rel-eng/build_instructions/build_openshift_origin.sh -h
```

For OpenShift V4 builds, use the following commands:
```
./rel-eng/build_instructions/build_openshift_origin.sh \
                        -m epel-6-x86_64-openshiftv4 \
                        -r v4 \
                        -s /var/tmp/origin-v4-srpms
```

For OpenShift nightly builds, use the following commands:
```
./rel-eng/build_instructions/build_openshift_origin.sh \
                        -m epel-6-x86_64-openshift-nightly \
                        -r nightly \
                        -s /var/tmp/origin-v4-srpms
```

At the end of this build task, you should have all the built rpms in a directory under `/var/tmp/`, the information will be output at the end of the script from the mockchain command.

We can now create a yum repository out of it with the `createrepo` or use them how ever we please.


## Using Fedora 
`#FIXME - add content here later`
Technically the instructions above will also work on Fedora since we use mock to perform the actual builds but the resulting rpms will not function on Fedora at this time. This is something we're targeting with a later release of OpenShift Origin.
