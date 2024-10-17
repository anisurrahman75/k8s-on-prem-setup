### Step-by-Step Guide to Set Up a Kubernetes Cluster (Master and Worker Nodes)

This guide will walk you through setting up a Kubernetes cluster on Ubuntu-based machines. It involves preparing the system, installing necessary components (like Docker and Kubernetes), and configuring the nodes (Master and Worker) to join the cluster.

---

### **1. Disable Swap (Recommended for Kubernetes)**
Kubernetes requires swap to be disabled for stable performance.

```bash
swapoff -a
sed -i '/swap/d' /etc/fstab
```
- `swapoff -a`: Temporarily disables swap.
- `sed -i '/swap/d' /etc/fstab`: Ensures swap is not re-enabled after a reboot by removing related entries from `/etc/fstab`.

---

### **2. Load Kernel Modules Required by Kubernetes**
Certain kernel modules need to be loaded for networking and container operations to work correctly.

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```
- This creates a configuration file to load the `overlay` and `br_netfilter` modules on boot.

---

### **3. Load Kernel Modules Immediately**
Execute the following to load the required modules without rebooting.

```bash
modprobe overlay
modprobe br_netfilter
```

---

### **4. Configure Kernel Parameters for Kubernetes Networking**
Networking settings need to be adjusted to ensure that traffic routing and bridge filtering are properly handled.

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```
- These settings allow traffic from the bridge network to go through iptables and enable packet forwarding in IPv4.

---

### **5. Apply Kernel Parameter Changes**
Run the following command to apply the new configurations.

```bash
sysctl --system
```

---

### **6. Install Essential Packages**
Install necessary packages for secure communications and transport.

```bash
apt-get install -y apt-transport-https ca-certificates curl gpg
```

---

### **7. Add Kubernetes APT Repository Key**
Download and store the Kubernetes repository’s GPG key.

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

---

### **8. Add Kubernetes Repository to APT Sources**
Enable the Kubernetes APT repository by creating a new entry.

```bash
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
```

---

### **9. Install Kubernetes Components**
Update the package list and install the required Kubernetes tools.

```bash
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
```
- **kubelet**: The agent running on all nodes.
- **kubeadm**: A tool to initialize and join Kubernetes clusters.
- **kubectl**: Command-line tool to interact with the cluster.
- **kubernetes-cni**: Networking plugins required for communication within the cluster.

---

### **10. Install and Configure Docker (Container Runtime)**
Kubernetes requires a container runtime, and Docker is a commonly used option.

```bash
apt install docker.io -y
mkdir /etc/containerd
sh -c "containerd config default > /etc/containerd/config.toml"
sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
```
- This installs Docker, creates a configuration directory for `containerd`, and updates the config to ensure that `systemd` is used for managing cgroups.

---

### **11. Restart and Enable Services**
Restart the required services to apply changes and enable them to start on boot.

```bash
systemctl restart containerd.service
systemctl restart kubelet.service
systemctl enable kubelet.service
```

---

### **12. Set Up the Master Node**
On the Master node, follow these steps to initialize the cluster and pull the necessary images.

1. **Pull Kubernetes Images**
   ```bash
   kubeadm config images pull
   ```

2. **Initialize the Cluster**
   ```bash
   kubeadm init
   ```

3. **Check the Master Node's Readiness**
   ```bash
   kubectl get --raw='/readyz?verbose'
   ```

4. **Install a Network Plugin (e.g., Calico)**  
   For the Kubernetes cluster to function properly, a networking solution is needed. Calico is a popular choice.  
   Follow the instructions from the [Calico Documentation](https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises) to install it.

---

### **13. Set Up the Worker Nodes**
On each Worker node, run the following to generate a command that allows nodes to join the cluster.

```bash
kubeadm token create --print-join-command
```
- Copy the generated command and execute it on each Worker node to join the cluster.

---

This process covers the installation and configuration of both Master and Worker nodes, providing a complete environment for your Kubernetes cluster.