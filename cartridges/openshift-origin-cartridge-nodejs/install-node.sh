#!/bin/bash

# Show script usage
usage() {
  echo "Usage: $0 [options]"
  echo
  echo "Where:"
  echo "  -r|--registry=<URL>           : NPM registry for pulling packages"
  echo "  -b|--binary-tarball=<URL>     : Location of node installer binaries (tar.gz format)"
  echo "  -v|--version=<Version Number> : Version of nodejs to install"
  echo "  -h|--help=                    : Show Help info"
}

# Process input
for i in "$@"
do
  case $i in
    -r=*|--registry=*)
      registryUrl="${i#*=}"
      npm_opts="--registry=${i#*=} ${npm_opts}"
      shift;;
    -b=*|--binary-tarball=*)
      tarfile="${i#*=}"
      shift;;
    -v=*|--version=*)
      NODE_VERSION="${i#*=}"
      shift;;
    -h|--help)
      usage
      exit 0;
      shift;;
    *)
    echo "Invalid Option: ${i#*=}"
    exit 1;
    ;;
  esac
done

[ -z $NODE_VERSION ] && echo "Version not set. Use -h or --help options for usage info" && exit 1

# Envrionment Setup
default_tarfile="http://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz"
NODE_TARBALL=${tarfile:-$default_tarfile}
NODE_INSTALL_DIR='/opt/nodejs'
OPENSHIFT_PATH_ELEMENT='/etc/openshift/env/PATH'
PROFILE_D_NODEJS='/etc/profile.d/node.sh'

echo "Downloading and Installing NodeJS version ${NODE_VERSION}"

mkdir -p $NODE_INSTALL_DIR

pushd /tmp > /dev/null
rm -f node-*.tar.gz
curl -sS -O $NODE_TARBALL
popd > /dev/null

pushd $NODE_INSTALL_DIR > /dev/null
tar zxf /tmp/node-*.tar.gz
popd > /dev/null

NODE_HOME=$(find $NODE_INSTALL_DIR -type d -name "node-v${NODE_VERSION}*")
echo "export PATH=\"${NODE_HOME}/bin:\$PATH\"" > ${PROFILE_D_NODEJS} && source ${PROFILE_D_NODEJS}

if [ $(grep -c "$NODE_INSTALL_DIR" $OPENSHIFT_PATH_ELEMENT) -lt 1 ]; then
  echo "${NODE_HOME}/bin:$(cat ${OPENSHIFT_PATH_ELEMENT})" > $OPENSHIFT_PATH_ELEMENT
fi

# Check that the system properly recognizes the node install
if [ "$(node -v)" != "v${NODE_VERSION}" ] || [ "$(which npm)" != "${NODE_HOME}/bin/npm" ]; then
  echo "Wrong node version installed. Something in the PATH settings was likely not set up correctly.
Check the following files for misinformation:
  - ${OPENSHIFT_PATH_ELEMENT}
  - ${PROFILE_D_NODEJS}"
  exit 1
fi

# Configure NPM
if [ -n ${registryUrl} ]; then
  npm config set registry ${registryUrl} -g
fi

# Install Modules
modulefile=$(find /var/lib/openshift/.cartridge_repository/redhat-nodejs/ -name npm_global_module_list | tail -n1)
modules=$(grep -v '#' $modulefile | grep -v '^$')

for mod in $modules; do
  echo "Installing ${mod} module..."
  npm install -g $mod ${npm_opts} &> /dev/null
done
