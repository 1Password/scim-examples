#!/usr/bin/env bash

# Docker Swarm deployment script
# Ensure you've read PREPARATION.md and docker/README.md

# set the full path of the docker examples directory

# function used to set up through Docker Compose
run_docker_compose() {
    echo " "
    echo "Deploying using Docker Compose..."
    echo "(Ctrl+C to cancel)"
    sleep 3

    # this command populates an .env file which allows the container to have a needed environment variable without needing to store the scimsession file itself
    SESSION=$(cat $scimsession_file | base64 | tr -d "\n")
    sed -i  -e "s/^OP_SESSION=.*$/OP_SESSION=$SESSION/" $docker_file_path/scim.env
    if $workspaceIdP
    then
        WORKSPACE_FILE=$(cat $workspace_settings | base64 | tr -d "\n")
        sed -i  -e "s/^OP_WORKSPACE_SETTINGS=.*$/OP_WORKSPACE_SETTINGS=$WORKSPACE_FILE/" $docker_file_path/scim.env

        GOOGLE_KEY_FILE=$(cat $google_credentials | base64 | tr -d "\n")
        sed -i  -e "s/^OP_WORKSPACE_CREDENTIALS=.*$/OP_WORKSPACE_CREDENTIALS=$GOOGLE_KEY_FILE/" $docker_file_path/scim.env
    fi

    if ! docker-compose -f $docker_file up --build -d
    then
        echo " "
        echo "Failed to run docker-compose; investigate the error before proceeding"
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
        echo "Failed to create Docker Swarm secret; investigate the error before proceeding"
        sleep 1
        exit 1
    fi

    if ! $workspaceIdP
    then
        if ! docker stack deploy -c $docker_file op-scim
        then
            echo " "
            echo "Failed to deploy to Docker Swarm; investigate the error before proceeding"
            sleep 1
            exit 1
        fi
    else
        if ! cat $workspace_settings | docker secret create workspace-settings -
        then
            echo " "
            echo "Failed to create Google Workspace settings secret in Docker; investigate the error before proceeding"
            sleep 1
            exit 1
        fi
        if ! cat $google_credentials | docker secret create workspace-credentials -
        then
            echo " "
            echo "Failed to create Google Service Account key secret in Docker; investigate the error before proceeding"
            sleep 1
            exit 1
        fi
        if ! docker stack deploy -c $docker_file -c $gw_docker_file op-scim
        then
            echo " "
            echo "Failed to deploy to Docker Swarm; investigate the error before proceeding"
            sleep 1
            exit 1
        fi
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
workspaceIdP=false

echo "Initiating 1Password SCIM Bridge Deployment to Docker Swarm"
echo " "
echo "Please specify the following options."

while ! [[ "$workspace" =~ ^([yY][eE][sS]|[yY]|[nN][oO]|[nN])$ ]]; do
    read -p "Are you using Google Workspace as your Identity Provider? [y/n]: " workspace
    if [[ "$workspace" =~ ^([yY][eS][sS]|[yY])$ ]]
    then
        workspaceIdP=true
        break
    fi
done

if $workspaceIdP
then
    while :
    do
        read -p "Path to your Google Workspace settings file: " workspace_settings
        if [[ -f "$workspace_settings" ]]
        then
            break
        fi
        echo "File '$workspace_settings' does not exist at that path, please try again." >&2
    done
    while :
    do
        read -p "Path to your Google Service Account key file: " google_credentials
        if [[ -f "$google_credentials" ]]
        then
            break
        fi
        echo "File '$google_credentials' does not exist at that path, please try again." >&2
    done
fi

while :
do
    read -p "Docker Swarm or Docker Compose? [swarm/compose]: " docker_type
    if [[ "$docker_type" =~ ^(swarm|compose)$ ]]
    then
        break
    fi
    echo "$docker_type is not a valid input. Please select either 'swarm' or 'compose'."
done

while :
do
    read -p "Fully-qualified domain name (FQDN) you are deploying to [e.g: 'op-scim.example.com']: " domain_name
    if [[ $domain_name = *.* ]]
    then
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
echo "Using the following parameters to deploy the SCIM bridge"
echo "Deployment type:" $docker_type
echo "scimsession file path:" $scimsession_file
echo "Domain name:" $domain_name
echo "Google Workspace as IdP:" $workspace

if $workspaceIdP
then
    echo "Workspace settings file path:" $workspace_settings
    echo "Google Service Account credentials file path:" $google_credentials
fi

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
gw_docker_file=$docker_file_path/gw-docker-compose.yml
docker_backup_file=$docker_file_path/docker-compose.yml.bak
gw_docker_backup_file=$docker_file_path/gw_docker-compose.yml.bak
cp $docker_file $docker_backup_file
sed -i  -e "s/^OP_TLS_DOMAIN=.*$/OP_TLS_DOMAIN=$domain_name/" $docker_file_path/scim.env

# run the function associated with the Docker type selected
if [[ "$docker_type" == "compose" ]]
then
    run_docker_compose
elif [[ "$docker_type" == "swarm" ]]
then
    cp $gw_docker_file $gw_docker_backup_file
    run_docker_swarm
fi

echo " "
echo "Deployment of the 1Password SCIM Bridge is complete!"
echo " "
echo "If you have any issues deploying the SCIM bridge, please either reach out to 1Password Business Support, or look through our helpful discussion forums: https://discussions.agilebits.com/categories/scim-bridge"
echo " "
