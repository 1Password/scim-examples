#!/usr/bin/env bash

# Docker Swarm deployment script
# Please ensure you've read PREPARING.md and docker/README.md

# set the full path of the docker examples directory
docker_path=$(dirname $(realpath $0))

echo "Initiating 1Password SCIM Bridge Deployment to Docker Swarm"
echo " "
echo "Please specify the following options."

while ! [[ "$docker_type" =~ ^(swarm|compose)$ ]]; do
    read -p "Docker Swarm or Docker Compose? [swarm/compose]: " docker_type
done

read -p "Domain name you are deploying to [e.g: 'op-scim.example.com']: " domain_name

while ! [[ -f "$scimsession_file" ]]; do
    read -p "Path to your scimsession file: " scimsession_file
    if ! [[ -f "$scimsession_file" ]]
    then
        echo "File '$scimsession_file' does not exist at that path, please try again." >&2
    fi
done

echo " "
echo "Using the following parameters to deploy the SCIM Bridge"
echo "Deployment type:" $docker_type
echo "scimsession file path:" $scimsession_file
echo "Domain name:" $domain_name

while ! [[ "$proceed" =~ ^([yY][eE][sS]|[yY])$ || "$proceed" =~ ^([nN][oO][nN]) ]]; do
    read -p "Does this look correct? [Y/n]: " proceed
    if [[ "$proceed" =~ ^([nN][oO][nN])$ ]]
    then
        echo "Exiting..."
        exit 1
    fi
done

# place the domain name into the deployment file, in a backup
docker_file_path=$docker_path/$docker_type
docker_original_file=$docker_file_path/docker-compose.yml
docker_deploy_file=$docker_file_path/docker-compose.yml.deploy
sed s/{YOUR-DOMAIN-HERE}/$domain_name/g $docker_original_file > $docker_deploy_file

if [[ "$docker_type" == "compose" ]]
then
    echo " "
    echo "Deploying using Docker Compose..."
    echo "(Ctrl+C to cancel)"
    sleep 3

    # this command populates an .env file which allows the container to have a needed environment variable without needing to store the scimsession file itself
    SESSION=$(cat $scimsession_file | base64 | tr -d "\n")
    echo "OP_SESSION=$SESSION" > $docker_path/$docker_type/scim.env

    if ! docker-compose -f $docker_deploy_file up --build -d
    then
        echo " "
        echo "Failed to run docker-compose, please investigate the error"
        sleep 1
        exit 1
    fi

    while ! [[ "$view_logs" =~ ^([yY][eE][sS]|[yY])$ || "$view_logs" =~ ^([nN][oO][nN]) ]]; do
        read -p "Do you want to view the logs? [Y/n]: " view_logs
        if [[ "$view_logs" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            echo " "
            echo "Press Ctrl+C to quit out of the log view."
            sleep 2
            docker-compose -f $docker_deploy_file logs -f 2>/dev/null
        elif [[ "$view_logs" =~ ^([nN][oO][nN])$ ]]
        then
            echo "Skipping logs..."
            echo "You can view the logs manually by running: docker-compose logs -f"
        fi
    done

elif [[ "$docker_type" == "swarm" ]]
then
    echo " "
    echo "Deploying using Docker Swarm..."
    echo "(Ctrl+C to cancel)"
    sleep 3

    # puts the scimsession secret into the Swarm
    if ! cat $scimsession_file | docker secret create scimsession -
    then
        echo " "
        echo "Failed to create Docker Swarm secret, please investigate the error"
        sleep 1
        exit 1
    fi

    if ! docker stack deploy -c $docker_deploy_file op-scim
    then
        echo " "
        echo "Failed to deploy to Docker Swarm, please investigate the error"
        sleep 1
        exit 1
    fi

    while ! [[ "$view_logs" =~ ^([yY][eE][sS]|[yY])$ || "$view_logs" =~ ^([nN][oO][nN]) ]]; do
        read -p "Do you want to view the logs? [Y/n]: " view_logs
        if [[ "$view_logs" =~ ^([yY][eE][sS]|[yY])$ ]]
        then
            echo " "
            echo "Press Ctrl+C to quit out of the log view."
            sleep 2
            docker service logs --raw -f op-scim_scim 2>/dev/null
        elif [[ "$view_logs" =~ ^([nN][oO][nN])$ ]]
        then
            echo "Skipping logs..."
            echo "You can view the logs manually by running: docker service logs --raw -f op-scim_scim"
        fi
    done
fi

echo " "
echo "Deployment of the 1Password SCIM Bridge is complete!"
echo " "
echo "If you have any issues deploying the SCIM Bridge, please either reach out to 1Password Business Support, or look through our helpful discussion forums: https://discussions.agilebits.com/categories/scim-bridge"
echo " "
echo "Back up of deployment docker-compose.yml file saved to" $docker_deploy_file
