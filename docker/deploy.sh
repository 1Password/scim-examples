#!/bin/bash

echo "Initiating 1Password SCIM Bridge Deployment"

run_docker_compose() {
    mv ./scimsession ./docker/compose/scimsession

    set -e # if the scimsession is already in ^, don't fail

    cd docker/compose
    ./generate-env.sh
    mv ./scimsession ../../

    read -p 'Please enter your domain name : ' domain_name

    sed -i '' s/{YOUR-DOMAIN-HERE}/$domain_name/g docker-compose.yml

    docker-compose up --build -d
    sed -i '' s/$domain_name/{YOUR-DOMAIN-HERE}/g docker-compose.yml

    docker-compose logs -f
}

run_docker_swarm(){
    mv ./scimsession ./docker/swarm/scimsession
    cd docker/swarm
    ./generate-secret.sh

    set -e # if the secret already exists, don't fail

    mv ./scimsession ../../

    read -p 'Please enter your domain name : ' domain_name

    sed -i '' s/{YOUR-DOMAIN-HERE}/$domain_name/g docker-compose.yml

    docker stack deploy -c docker-compose.yml op-scim
    sed -i '' s/$domain_name/{YOUR-DOMAIN-HERE}/g docker-compose.yml

    docker service logs --raw -f op-scim_scim
}

read -p 'Please enter the configuration you are using [compose] or [swarm] : ' docker_path

if [ "$docker_path" == "compose" ];
then 
    run_docker_compose
elif [ "$docker_path" == "swarm" ]
then
    run_docker_swarm
else 
    echo "Invalid docker manager. Please use docker-compose or docker-swarm"
    exit
fi
