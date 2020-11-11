#!/usr/bin/env bash

# Docker Swarm deployment script
# Please ensure you've read PREPARATION.md and docker/README.md

# set the full path of the docker examples directory

# function used to set up through Docker Compose
run_docker_compose() {
    echo " "
    echo "Deploying using Docker Compose..."
    echo "(Ctrl+C to cancel)"
    sleep 3

    # this command populates an .env file which allows the container to have a needed environment variable without needing to store the scimsession file itself
    SESSION=$(cat $scimsession_file | base64 | tr -d "\n")
    sed -i '' -e "s/^OP_SESSION=.*$/OP_SESSION=$SESSION/" $docker_path/$docker_type/scim.env

    if ! docker-compose -f $docker_file up --build -d
    then
        echo " "
        echo "Failed to run docker-compose, please investigate the error"
        sleep 1
        exit 1
    fi

    read -p "Do you want to view the logs? [Y/n]: " view_logs

    if [[ "$view_logs" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo " "
        echo "Press Ctrl+C to quit out of the log view."
        sleep 2
        docker-compose -f $docker_file logs -f 2>/dev/null
    else
        echo "Skipping logs..."
        echo "You can view the logs manually by running: docker-compose logs -f"
    fi
}

# function used to set up through Docker Swarm
run_docker_swarm() {
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

    if ! docker stack deploy -c $docker_file op-scim
    then
        echo " "
        echo "Failed to deploy to Docker Swarm, please investigate the error"
        sleep 1
        exit 1
    fi

    read -p "Do you want to view the logs? [Y/n]: " view_logs
    if [[ "$view_logs" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo " "
        echo "Press Ctrl+C to quit out of the log view."
        sleep 2
        docker service logs --raw -f op-scim_scim 2>/dev/null
    else
        echo "Skipping logs..."
        echo "You can view the logs manually by running: docker service logs --raw -f op-scim_scim"
    fi
}

# Begin main script

docker_path=$(dirname $(realpath $0))

echo "Initiating 1Password SCIM Bridge Deployment to Docker Swarm"
echo " "
echo "Please specify the following options."

while :
do
    read -p "Docker Swarm or Docker Compose? [swarm/compose]: " docker_type
    if [[ "$docker_type" =~ ^(swarm|compose)$ ]]; then
        break
    fi
    echo "$docker_type is not a valid input. Please select either 'swarm' or 'compose'."
done


while :
do
    read -p "Fully-qualified domain name (FQDN) you are deploying to [e.g: 'op-scim.example.com']: " domain_name
    if [[ $domain_name = *.* ]]; then
        break
    fi
    echo "Please enter a fully-qualified domain name."
done

while :
do
    read -p "Path to your scimsession file: " scimsession_file
    if [[ -f "$scimsession_file" ]]
    then
        break
    fi
    echo "File '$scimsession_file' does not exist at that path, please try again." >&2
done

echo " "
echo "Using the following parameters to deploy the SCIM Bridge"
echo "Deployment type:" $docker_type
echo "scimsession file path:" $scimsession_file
echo "Domain name:" $domain_name

while ! [[ "$proceed" =~ ^([yY][eE][sS]|[yY])$ ]]; do
    read -p "Does this look correct? [Y/n]: " proceed
    if [[ "$proceed" =~ ^([nN][oO][nN])$ ]]
    then
        echo "Exiting..."
        exit 0
    fi
done

# place the domain name into the deployment file, in a backup
docker_file_path=$docker_path/$docker_type
docker_file=$docker_file_path/docker-compose.yml
docker_backup_file=$docker_file_path/docker-compose.yml.bak
cp $docker_file $docker_backup_file
sed -i '' -e "s/^OP_LETSENCRYPT_DOMAIN=.*$/OP_LETSENCRYPT_DOMAIN=$domain_name/" $docker_path/$docker_type/scim.env

# run the function associated with the Docker type selected
if [[ "$docker_type" == "compose" ]]
then
    run_docker_compose
elif [[ "$docker_type" == "swarm" ]]
then
    run_docker_swarm
fi

echo " "
echo "Deployment of the 1Password SCIM Bridge is complete!"
echo " "
echo "If you have any issues deploying the SCIM Bridge, please either reach out to 1Password Business Support, or look through our helpful discussion forums: https://discussions.agilebits.com/categories/scim-bridge"
echo " "
