#!/bin/bash

mkdir session

docker run -it -v $PWD/session:'/op-scim/session' -v $HOME/.op:'/root/.op' 1password/scim:v0.8.2 /op-scim/create-session-docker.sh

cp ./session/scimsession ./scimsession
rm -rf ./session