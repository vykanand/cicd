#!/bin/bash

# Function to check for updates and restart if necessary
check_updates_and_restart() {
  local package_name=$1
  local service_name=$2

  # Check for updates
  sudo apt-get update -qq
  local updates_available=$(apt-get -s upgrade $package_name | grep -c '^[[:alnum:]]')

  if [ $updates_available -gt 0 ]; then
    echo "Updates available for $package_name. Updating and restarting $service_name..."

    # Perform the update
    sudo apt-get upgrade -y $package_name

    # Restart the service if it is running
    if sudo systemctl is-active --quiet $service_name; then
      sudo systemctl restart $service_name
    fi

    return 1
  fi

  return 0
}

# Update the system and restart if necessary
if check_updates_and_restart "docker-ce" "docker"; then
  echo "No updates available for Docker."
else
  # Wait for Docker service to start
  sleep 5
fi

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Docker prerequisites
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add the Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add the Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package list and restart if necessary
if check_updates_and_restart "containerd.io" "containerd"; then
  echo "No updates available for containerd."
else
  # Wait for containerd service to start
  sleep 5
fi

# Restart multipathd.service if necessary
if check_updates_and_restart "multipath-tools" "multipathd"; then
  echo "Multipathd.service updated and restarted."
else
  # Wait for multipathd.service to start
  sleep 5
fi

# Install kubelet and kubectl
sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Configure kubelet
echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$(hostname -I | awk '{print $1}')\"" | sudo tee -a /etc/systemd/system/kubelet.conf

# Restart kubelet if necessary
if check_updates_and_restart "kubelet" "kubelet"; then
  echo "Kubelet updated and restarted."
else
  # Wait for kubelet service to start
  sleep 5
fi

# Enable bridge-nf-call-iptables
echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system

# Enable ip forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
sudo sysctl --system

# Done
echo "Kubernetes worker node setup completed."
