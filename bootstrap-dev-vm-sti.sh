#!/bin/bash
echo "Initialize Vagrant VM for Origin Server development via STI builds"

# DOCKER IMAGES TO PULL
MONGO_IMAGE=openshift/ubuntu-mongodb
BROKER_IMAGE=openshift-origin-broker

# CONTAINER NAMES
MONGODB=origin-mongodb-1
BROKER=origin-broker-1

# PATHS TO COMMMON RESOURCES
OPENSHIFT=/vagrant/src/github.com/openshift
GEARD=$OPENSHIFT/geard
ORIGIN_SERVER=$OPENSHIFT/origin-server
CARTRIDGES=$OPENSHIFT/cartridges
GITHOST_SERVICE_FILE=/var/lib/containers/units/geard-githost.service
DEPLOYMENT_FILE=$ORIGIN_SERVER/openshift_dev_deploy.json

echo "Verifying Go workspace"
if [ -d $ORIGIN_SERVER ]; then
  echo "Go workspace validated"
else
  echo "Go workspace is missing $ORIGIN_SERVER directory"
  exit 1
fi

# BUILD THE OPENSHIFT-ORIGIN-BROKER IMAGE IF NOT FOUND
if [[ $( docker images | grep $BROKER_IMAGE ) = "" ]]; then
  echo "Build image: $BROKER_IMAGE"
  docker build --rm -t $BROKER_IMAGE $ORIGIN_SERVER/.
else
  echo "Using local image: $BROKER_IMAGE"
fi

if [[ $( docker images | grep $MONGO_IMAGE ) = "" ]]; then
  echo "Pull image: $MONGO_IMAGE"
  docker pull $MONGO_IMAGE
else
  echo "Using local image: $MONGO_IMAGE"
fi

echo "Performing gear deploy"
gear deploy $DEPLOYMENT_FILE

MONGO_IPADDRESS=$( docker inspect $MONGODB | grep IPAddress )
MONGO_HOST_PORT=${MONGO_IPADDRESS:22:-2}:27017

echo "Populating Broker Mongo Prereqs"
docker run --rm -i -e "MONGO_HOST_PORT=$MONGO_HOST_PORT" -v $ORIGIN_SERVER:/var/www/openshift/ $BROKER_IMAGE /bin/bash --login /var/www/openshift/bootstrap-dev-vm-mongo.sh

# CHECK GEARD-GITHOST STATUS
if [ -f $GITHOST_SERVICE_FILE ]; then
  echo "Enable and start geard-githost"
  systemctl enable $GITHOST_SERVICE_FILE
  systemctl start geard-githost
else
  echo "The Git host service file is not found."
  echo " -- Ensure geard is running on host"
  echo " -- Git repository creation via $BROKER operations will fail"
fi

echo "To interact with broker, use http://localhost:6060"
echo "Done"