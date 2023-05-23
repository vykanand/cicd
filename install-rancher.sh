#!/bin/bash

# Update package index and upgrade packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
# sudo apt-get install -y docker.io
curl https://releases.rancher.com/install-docker/20.10.sh | sh

docker run -d --restart=unless-stopped -p 999:8080 rancher/server:stable