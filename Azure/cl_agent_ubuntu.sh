#!/bin/bash

# Configuration variables
install_docker="y"  # Set to "y" to install Docker, "n" to skip
os_option=1          # Set the OS option (1 for Ubuntu)
cloudlens_manager_ip_or_FQDN="10.36.234.91"  # Replace with your CloudLens Manager IP or FQDN
project_key="dc26afd7808d499183fd00739254281a"  # Replace with your Project Key
custom_tags="env=azure"  # Replace with your custom tags
set_registry="y"  # Set to "y" for insecure registry, "n" for secure with SSL
ca_path="/path/to/ca.crt"  # Replace with the path to your CA file if using SSL

# Function to check if Docker is already installed
check_docker_installed() {
    if command -v docker &> /dev/null; then
        echo "Docker is already installed."
        sleep 2
        return 0
    else
        echo "Docker is not installed."
        sleep 2
        return 1
    fi
}

# Function to install Docker on Ubuntu
install_docker_ubuntu() {
    echo -e "\nInstalling Docker on Ubuntu..."
    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker installed successfully on Ubuntu!"
    sleep 2
}

# Function to verify Docker installation and start Docker if needed
verify_docker() {
    echo -e "\nVerifying Docker installation..."
    docker_status=$(sudo systemctl is-active docker)
    if [ "$docker_status" = "active" ]; then
        echo "Docker is running successfully."
    else
        echo "Docker is not running. Attempting to start Docker..."
        sudo systemctl start docker
        if [ "$(sudo systemctl is-active docker)" = "active" ]; then
            echo "Docker started successfully."
        else
            echo "Failed to start Docker. Exiting."
            sleep 2
            exit 1
        fi
    fi
    sleep 2
}

# Function to set insecure registry and handle SSL verification
set_insecure_registry() {
    echo -e "\nConfiguring Docker registry..."
    if [ "$set_registry" == "y" ]; then
        echo "Setting insecure Docker registry..."
        echo "{\"insecure-registries\":[\"$cloudlens_manager_ip_or_FQDN\"]}" | sudo tee /etc/docker/daemon.json
        sudo service docker restart
        echo "Insecure registry set and Docker restarted."
    else
        echo "Secure Docker registry selected. SSL verification is required."
        if [ -f "$ca_path" ]; then
            echo "CA file found at $ca_path. The certificate will be mounted in the Docker container."
        else
            echo "CA file not found at the provided path. Exiting."
            sleep 2
            exit 1
        fi
    fi
    sleep 2
}

# Function to install CloudLens agent with appropriate SSL settings
install_cloudlens_agent() {
    echo -e "\nInstalling CloudLens agent..."
    # Base Docker run command
    docker_command="sudo docker run -v /lib/modules:/lib/modules \
    -v /var/log/cloudlens:/var/log/cloudlens \
    -v /:/host -v /var/run/docker.sock:/var/run/docker.sock \
    --cap-add NET_BROADCAST --cap-add SYS_ADMIN --cap-add SYS_MODULE \
    --cap-add SYS_RESOURCE --cap-add NET_RAW --cap-add NET_ADMIN \
    --name cloudlens-agent -d --restart=always --net=host \
    --log-opt max-size=50m --log-opt max-file=5 \
    \"$cloudlens_manager_ip_or_FQDN\"/sensor --accept_eula yes \
    --project_key \"$project_key\" --server \"$cloudlens_manager_ip_or_FQDN\" \
    --custom_tags \"$custom_tags\""

    if [ "$set_registry" == "y" ]; then
        docker_command="$docker_command --ssl_verify no"
    else
        docker_command="$docker_command -v \"$ca_path:/usr/local/share/ca-certificates:ro\""
        echo "CA certificate will be mounted as a volume."
    fi

    eval $docker_command || { echo "Failed to install CloudLens agent."; exit 1; }
    echo "CloudLens agent installed successfully!"
    sleep 2
}

# Function to start ntopng container for Azure
start_ntopng_azure() {
    echo -e "\nStarting ntopng container on Azure..."
    sudo docker pull ntop/ntopng:stable
    sudo docker run --net=host --name ntopng -t -d --restart=always ntop/ntopng:stable ntopng --interface=cloudlens0 --community --user=admin --disable-login=1 disable-autologout || { echo "Failed to start ntopng container on Azure."; exit 1; }
    echo "ntopng container started successfully on Azure!"
    sleep 2
}

# Check if Docker should be installed
if [ "$install_docker" == "y" ]; then
    # Check if Docker is installed
    if check_docker_installed; then
        echo "Skipping Docker installation."
    else
        case $os_option in
            1) install_docker_ubuntu ;;
            *)
                echo "Invalid OS option. Please choose 1."
                sleep 2
                exit 1
                ;;
        esac
    fi

    # Verify Docker installation
    verify_docker
else
    echo "Skipping Docker installation."
fi

# Set insecure registry or configure SSL verification
set_insecure_registry 

# Install CloudLens agent on Azure
install_cloudlens_agent
start_ntopng_azure

# Verify running Docker containers
sudo docker ps -a
echo "Script execution complete!"
