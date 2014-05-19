#!/bin/bash
echo "Initialize Vagrant VM for Origin Server development via bind mounts"

# DOCKER IMAGES TO PULL
MONGO_IMAGE=openshift/ubuntu-mongodb
BROKER_IMAGE=openshift-origin-broker

# CONTAINER NAMES
MONGODB=origin-mongodb
BROKER=origin-broker

# PATHS TO COMMMON RESOURCES
OPENSHIFT=/vagrant/src/github.com/openshift
GEARD=$OPENSHIFT/geard
ORIGIN_SERVER=$OPENSHIFT/origin-server
CARTRIDGES=$OPENSHIFT/cartridges
GITHOST_SERVICE_FILE=/var/lib/containers/units/geard-githost.service

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

if [[ $( docker ps -a | grep $MONGODB ) = "" ]]; then
  echo "Creating $MONGODB container"
  docker run --name $MONGODB -d -P $MONGO_IMAGE
else
  if [[ $( docker ps | grep $MONGODB ) = "" ]]; then
    echo "Starting $MONGODB container"
    docker start $MONGODB
  else
    echo "Container $MONGODB already started"
  fi
fi

MONGO_IPADDRESS=$( docker inspect $MONGODB | grep IPAddress )
MONGO_HOST_PORT=${MONGO_IPADDRESS:22:-2}:27017

if [[ $( docker ps -a | grep $BROKER ) = "" ]]; then
  echo "Creating $BROKER container"
  docker run --name $BROKER -d -i -t -p 3000:443 -e "MONGO_HOST_PORT=$MONGO_HOST_PORT" -v $ORIGIN_SERVER:/var/www/openshift/ $BROKER_IMAGE
else
  if [[ $( docker ps | grep $BROKER ) = "" ]]; then
    echo "Starting $BROKER container"
    docker start $BROKER
  else
    echo "Container $BROKER already started"
  fi
fi

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

echo "To interact with broker, use http://localhost:3000"
echo "Done"