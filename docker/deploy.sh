#!/bin/bash

set -e

run_docker_compose() {
    cp ./scimsession ./docker/compose/scimsession
    rm ./scimsession 
    cd docker/compose
    ./generate-env.sh

    read -p 'Please enter your domain name : ' domain_name

    sed -i '' s/{YOUR-DOMAIN-HERE}/$domain_name/g docker-compose.yml

    docker-compose up --build
}

run_docker_swarm(){
    cp ./scimsession ./docker/swarm/scimsession
    rm ./scimsession 
    cd docker/swarm
    ./generate-secret.sh

    read -p 'Please enter your domain name : ' domain_name

    sed -i '' s/{YOUR-DOMAIN-HERE}/$domain_name/g docker-compose.yml

    docker stack deploy -c docker-compose.yml op-scim
}

read -p 'Please enter the configuration you are using [docker-compose] or [docker-swarm] : ' docker_path

if [ "$docker_path" == "docker-compose" ];
then 
    run_docker_compose
elif [ "$docker_path" == "docker-swarm" ]
then
    run_docker_swarm
else 
    echo "Invalid docker manager. Please use docker-compose or docker-swarm"
    exit
fi
