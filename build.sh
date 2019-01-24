#!/bin/bash

set -e

read -p 'Please enter the configuration you are using [docker-compose] or [docker-swarm] : ' docker_path

if [ "$docker_path" == "docker-compose" ];
then 
    cp ./scimsession ./docker-compose/scimsession
    rm ./scimsession 
    cd docker-compose
    ./generate-env.sh
elif [ "$docker_path" == "docker-swarm" ]
then
    cp ./scimsession ./docker-swarm/scimsession
    rm ./scimsession 
    cd docker-swarm
    ./generate-secret.sh
else 
    echo "Invalid docker manager. Please use docker-compose or docker-swarm"
    exit
fi

read -p 'Please enter your domain name : ' domain_name

sed -i '' s/{YOUR-DOMAIN-HERE}/$domain_name/g docker-compose.yml

docker-compose up --build
