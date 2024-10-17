#!/bin/bash

set -e

# Function to disable swap
disable_swap() {
    swapoff -a
    sed -i '/swap/d' /etc/fstab
    echo "Swap disabled."
}

# Function to load kernel modules
load_kernel_modules() {
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

    modprobe overlay
    modprobe br_netfilter

    echo "Kernel modules loaded."
}

# Function to set kernel parameters
configure_kernel_parameters() {
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

    sysctl --system
    echo "Kernel parameters configured."
}

# Function to install prerequisite packages
install_prerequisites() {
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gpg
    echo "Prerequisite packages installed."
}

# Function to add Kubernetes APT repository
add_kubernetes_repo() {
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

    apt-get update
    echo "Kubernetes APT repository added."
}

# Function to install Kubernetes components
install_kubernetes() {
    apt-get install -y kubelet kubeadm kubectl kubernetes-cni
    echo "Kubernetes components installed."
}

# Function to install and configure Docker
install_configure_docker() {
    apt install docker.io -y

    mkdir -p /etc/containerd
    sh -c "containerd config default > /etc/containerd/config.toml"
    sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml

    systemctl restart containerd.service
    systemctl restart kubelet.service
    systemctl enable kubelet.service

    echo "Docker installed and configured."
}

# Function to initialize the Master node
initialize_master_node() {
    kubeadm config images pull
    kubeadm init

    echo "Master node initialized. Follow further instructions to complete the setup:"
    echo "1. To start using your cluster, run the following as a regular user:"
    echo "   mkdir -p \$HOME/.kube"
    echo "   sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config"
    echo "   sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"
    echo
    echo "2. To install the network plugin (e.g., Calico), visit:"
    echo "   https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises"
}

# Function to join a Worker node to the cluster
join_worker_node() {
    read -p "Enter the join command for the Worker node: " join_command
    eval $join_command
    echo "Worker node joined the cluster."
}

# Main script execution
echo "Starting Kubernetes setup script..."
disable_swap
load_kernel_modules
configure_kernel_parameters
install_prerequisites
add_kubernetes_repo
install_kubernetes
install_configure_docker

# Prompt user to set up as Master or Worker
read -p "Do you want to set up this node as a Master or Worker? (master/worker): " node_type

if [ "$node_type" == "master" ]; then
    initialize_master_node
elif [ "$node_type" == "worker" ]; then
    join_worker_node
else
    echo "Invalid input. Please specify 'master' or 'worker'."
    exit 1
fi

echo "Kubernetes setup completed."
