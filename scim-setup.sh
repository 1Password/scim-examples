#!/bin/bash

mkdir session

docker run -it -v $PWD/session:'/op-scim/session' 1password/scim:v0.7.2 /op-scim/create-session-docker.sh

cp ./session/scimsession ./scimsession
rm -rf ./session