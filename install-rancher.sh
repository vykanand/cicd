#!/bin/bash

# Update package index and upgrade packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
sudo apt-get install -y docker.io

sudo docker run --privileged -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher