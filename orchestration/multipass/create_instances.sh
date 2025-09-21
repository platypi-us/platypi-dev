#!/usr/bin/env bash

# variables
export CP01_IP="192.168.64.101";
export WORKER01_IP="192.168.64.111";
export WORKER02_IP="192.168.64.112";

# create instances
## cp01
multipass launch --disk 10G --memory 3G --cpus 2 --name cp01 --network name=en0,mode=manual,mac="52:54:00:4b:ab:cd" file://debian-13-generic-arm64-20250911-2232.qcow2;

multipass exec -n cp01 -- sudo bash -c "cat << EOF > /etc/netplan/10-custom.yaml
network:
  version: 2
  ethernets:
    extra0:
      dhcp4: no
      match:
        macaddress: "52:54:00:4b:ab:cd"
      addresses: [${CP01_IP}/24]
EOF";

multipass exec -n cp01 -- sudo netplan apply;


## worker01
multipass launch --disk 10G --memory 3G --cpus 2 --name worker01 --network name=en0,mode=manual,mac="52:54:00:4b:ba:dc" file://debian-13-generic-arm64-20250911-2232.qcow2;


multipass exec -n worker01 -- sudo bash -c "cat << EOF > /etc/netplan/10-custom.yaml
network:
  version: 2
  ethernets:
    extra0:
      dhcp4: no
      match:
        macaddress: "52:54:00:4b:ba:dc"
      addresses: [${WORKER01_IP}/24]
EOF";

multipass exec -n worker01 -- sudo netplan apply;

## worker02
multipass launch --disk 10G --memory 3G --cpus 2 --name worker02 --network name=en0,mode=manual,mac="52:54:00:4b:cd:ab" file://debian-13-generic-arm64-20250911-2232.qcow2;

multipass exec -n worker02 -- sudo bash -c "cat << EOF > /etc/netplan/10-custom.yaml
network:
  version: 2
  ethernets:
    extra0:
      dhcp4: no
      match:
        macaddress: "52:54:00:4b:cd:ab"
      addresses: [${WORKER02_IP}/24]
EOF";

multipass exec -n worker02 -- sudo netplan apply;

# /etc/hosts
## cp01
multipass exec -n cp01 -- sudo bash -c "cat << EOF >> /etc/hosts
${CP01_IP} cp01 cp01
${WORKER01_IP} worker01 worker01
${WORKER02_IP} worker02 worker02
EOF";

## worker01
multipass exec -n worker01 -- sudo bash -c "cat << 'EOF' >> /etc/hosts
${CP01_IP} cp01 cp01
${WORKER01_IP} worker01 worker01
${WORKER02_IP} worker02 worker02
EOF";

## worker02
multipass exec -n worker02 -- sudo bash -c "cat << 'EOF' >> /etc/hosts
${CP01_IP} cp01 cp01
${WORKER01_IP} worker01 worker01
${WORKER02_IP} worker02 worker02
EOF";

# kubernetes prerequisites
## cp01
multipass exec -n cp01 -- sudo bash -c "cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF";

multipass exec -n cp01 -- sudo modprobe overlay;
multipass exec -n cp01 -- sudo modprobe br_netfilter;

multipass exec -n cp01 -- sudo bash -c "cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF";

multipass exec -n cp01 -- sudo sysctl --system;

multipass exec -n cp01 -- sudo bash -c "swapoff -a";
multipass exec -n cp01 -- sudo bash -c "sed -i '/ swap / s/^/#/' /etc/fstab"

## worker01
multipass exec -n worker01 -- sudo bash -c "cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF";

multipass exec -n worker01 -- sudo modprobe overlay;
multipass exec -n worker01 -- sudo modprobe br_netfilter;

multipass exec -n worker01 -- sudo bash -c "cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF";

multipass exec -n worker01 -- sudo sysctl --system;

multipass exec -n worker01 -- sudo bash -c "swapoff -a";
multipass exec -n worker01 -- sudo bash -c "sed -i '/ swap / s/^/#/' /etc/fstab"

## worker02
multipass exec -n worker02 -- sudo bash -c "cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF";

multipass exec -n worker02 -- sudo modprobe overlay;
multipass exec -n worker02 -- sudo modprobe br_netfilter;

multipass exec -n worker02 -- sudo bash -c "cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF";

multipass exec -n worker02 -- sudo sysctl --system;

multipass exec -n worker02 -- sudo bash -c "swapoff -a";
multipass exec -n worker02 -- sudo bash -c "sed -i '/ swap / s/^/#/' /etc/fstab"

# Install containerd
## cp01
multipass exec -n cp01 -- sudo bash -c "curl -LO https://github.com/containerd/containerd/releases/download/v2.1.4/containerd-2.1.4-linux-arm64.tar.gz";
  multipass exec -n cp01 -- sudo bash -c "tar Cxzvf /usr/local containerd-2.1.4-linux-arm64.tar.gz";
multipass exec -n cp01 -- sudo bash -c "curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service";
multipass exec -n cp01 -- sudo bash -c "mkdir -p /usr/local/lib/systemd/system/";
multipass exec -n cp01 -- sudo bash -c "cp containerd.service /usr/local/lib/systemd/system/";
multipass exec -n cp01 -- sudo bash -c "mkdir -p /etc/containerd/";
multipass exec -n cp01 -- sudo bash -c "touch /etc/containerd/config.toml";
multipass exec -n cp01 -- sudo bash -c "containerd config default | tee ./config.toml";
multipass exec -n cp01 -- sudo bash -c "cp -f config.toml /etc/containerd/config.toml";
multipass exec -n cp01 -- sudo bash -c "sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml";
multipass exec -n cp01 -- sudo bash -c "systemctl daemon-reload";
multipass exec -n cp01 -- sudo bash -c "systemctl enable --now containerd";
multipass exec -n cp01 -- sudo bash -c "systemctl status containerd";

## worker01
multipass exec -n worker01 -- sudo bash -c "curl -LO https://github.com/containerd/containerd/releases/download/v2.1.4/containerd-2.1.4-linux-arm64.tar.gz";
multipass exec -n worker01 -- sudo bash -c "tar Cxzvf /usr/local containerd-2.1.4-linux-arm64.tar.gz";
multipass exec -n worker01 -- sudo bash -c "curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service";
multipass exec -n worker01 -- sudo bash -c "mkdir -p /usr/local/lib/systemd/system/";
multipass exec -n worker01 -- sudo bash -c "cp containerd.service /usr/local/lib/systemd/system/";
multipass exec -n worker01 -- sudo bash -c "mkdir -p /etc/containerd/";
multipass exec -n worker01 -- sudo bash -c "touch /etc/containerd/config.toml";
multipass exec -n worker01 -- sudo bash -c "containerd config default | tee ./config.toml";
multipass exec -n worker01 -- sudo bash -c "cp -f config.toml /etc/containerd/config.toml";
multipass exec -n worker01 -- sudo bash -c "sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml";
multipass exec -n worker01 -- sudo bash -c "systemctl daemon-reload";
multipass exec -n worker01 -- sudo bash -c "systemctl enable --now containerd";
multipass exec -n worker01 -- sudo bash -c "systemctl status containerd";

## worker02
multipass exec -n worker02 -- sudo bash -c "curl -LO https://github.com/containerd/containerd/releases/download/v2.1.4/containerd-2.1.4-linux-arm64.tar.gz";
multipass exec -n worker02 -- sudo bash -c "tar Cxzvf /usr/local containerd-2.1.4-linux-arm64.tar.gz";
multipass exec -n worker02 -- sudo bash -c "curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service";
multipass exec -n worker02 -- sudo bash -c "mkdir -p /usr/local/lib/systemd/system/";
multipass exec -n worker02 -- sudo bash -c "cp containerd.service /usr/local/lib/systemd/system/";
multipass exec -n worker02 -- sudo bash -c "mkdir -p /etc/containerd/";
multipass exec -n worker02 -- sudo bash -c "touch /etc/containerd/config.toml";
multipass exec -n worker02 -- sudo bash -c "containerd config default | tee ./config.toml";
multipass exec -n worker02 -- sudo bash -c "cp -f config.toml /etc/containerd/config.toml";
multipass exec -n worker02 -- sudo bash -c "sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml";
multipass exec -n worker02 -- sudo bash -c "systemctl daemon-reload";
multipass exec -n worker02 -- sudo bash -c "systemctl enable --now containerd";
multipass exec -n worker02 -- sudo bash -c "systemctl status containerd";

# install runc
## cp01
multipass exec -n cp01 -- sudo bash -c "curl -LO https://github.com/opencontainers/runc/releases/download/v1.3.1/runc.arm64";
multipass exec -n cp01 -- sudo bash -c "install -m 755 runc.arm64 /usr/local/sbin/runc";

## worker01
multipass exec -n worker01 -- sudo bash -c "curl -LO https://github.com/opencontainers/runc/releases/download/v1.3.1/runc.arm64";
multipass exec -n worker01 -- sudo bash -c "install -m 755 runc.arm64 /usr/local/sbin/runc";

## worker02
multipass exec -n worker02 -- sudo bash -c "curl -LO https://github.com/opencontainers/runc/releases/download/v1.3.1/runc.arm64";
multipass exec -n worker02 -- sudo bash -c "install -m 755 runc.arm64 /usr/local/sbin/runc";

# install CNI plugins
## cp01
multipass exec -n cp01 -- sudo bash -c "curl -LO https://github.com/containernetworking/plugins/releases/download/v1.8.0/cni-plugins-linux-arm64-v1.8.0.tgz";
multipass exec -n cp01 -- sudo bash -c "mkdir -p /opt/cni/bin";
multipass exec -n cp01 -- sudo bash -c "tar Cxzvf /opt/cni/bin cni-plugins-linux-arm64-v1.8.0.tgz";

## worker01
multipass exec -n worker01 -- sudo bash -c "curl -LO https://github.com/containernetworking/plugins/releases/download/v1.8.0/cni-plugins-linux-arm64-v1.8.0.tgz";
multipass exec -n worker01 -- sudo bash -c "mkdir -p /opt/cni/bin";
multipass exec -n worker01 -- sudo bash -c "tar Cxzvf /opt/cni/bin cni-plugins-linux-arm64-v1.8.0.tgz";

## worker02
multipass exec -n worker02 -- sudo bash -c "curl -LO https://github.com/containernetworking/plugins/releases/download/v1.8.0/cni-plugins-linux-arm64-v1.8.0.tgz";
multipass exec -n worker02 -- sudo bash -c "mkdir -p /opt/cni/bin"
multipass exec -n worker02 -- sudo bash -c "tar Cxzvf /opt/cni/bin cni-plugins-linux-arm64-v1.8.0.tgz"

# Install kubeadm, kubelet, and kubectl
## cp01
multipass exec -n cp01 -- sudo bash -c "apt-get update";
multipass exec -n cp01 -- sudo bash -c "apt-get install -y apt-transport-https ca-certificates curl gpg";
multipass exec -n cp01 -- sudo bash -c "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg";
multipass exec -n cp01 -- sudo bash -c "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list";
multipass exec -n cp01 -- sudo bash -c "apt-get update";
multipass exec -n cp01 -- sudo bash -c "apt-get install -y kubelet kubeadm kubectl";
multipass exec -n cp01 -- sudo bash -c "apt-mark hold kubelet kubeadm kubectl";

## worker01
multipass exec -n worker01 -- sudo bash -c "apt-get update";
multipass exec -n worker01 -- sudo bash -c "apt-get install -y apt-transport-https ca-certificates curl gpg";
multipass exec -n worker01 -- sudo bash -c "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg";
multipass exec -n worker01 -- sudo bash -c "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list";
multipass exec -n worker01 -- sudo bash -c "apt-get update";
multipass exec -n worker01 -- sudo bash -c "apt-get install -y kubelet kubeadm kubectl";
multipass exec -n worker01 -- sudo bash -c "apt-mark hold kubelet kubeadm kubectl";

## worker02
multipass exec -n worker02 -- sudo bash -c "apt-get update";
multipass exec -n worker02 -- sudo bash -c "apt-get install -y apt-transport-https ca-certificates curl gpg";
multipass exec -n worker02 -- sudo bash -c "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg";
multipass exec -n worker02 -- sudo bash -c "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list";
multipass exec -n worker02 -- sudo bash -c "apt-get update";
multipass exec -n worker02 -- sudo bash -c "apt-get install -y kubelet kubeadm kubectl";
multipass exec -n worker02 -- sudo bash -c "apt-mark hold kubelet kubeadm kubectl";

# configure crictl to work with containerd
## cp01
multipass exec -n cp01 -- sudo bash -c "crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
";

## worker01
multipass exec -n worker01 -- sudo bash -c "crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
";

## worker02
multipass exec -n worker02 -- sudo bash -c "crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
";

# Initialize the control plane; cp01 only
multipass exec -n cp01 -- sudo bash -c "kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${CP01_IP}";


# configure kubectl context on cp01
multipass exec -n cp01 -- bash -c 'mkdir -p ~/.kube';
multipass exec -n cp01 -- bash -c 'sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config';
multipass exec -n cp01 -- sudo bash -c "chown ubuntu:ubuntu /home/ubuntu/.kube/config";
multipass exec -n cp01 -- bash -c 'kubectl config get-contexts';
multipass exec -n cp01 -- bash -c 'kubectl get pods -A';

# install helm on cp01
multipass exec -n cp01 -- sudo bash -c 'apt-get install curl gpg apt-transport-https --yes';
multipass exec -n cp01 -- sudo bash -c 'apt-get update';
multipass exec -n cp01 -- sudo bash -c 'curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | tee /usr/share/keyrings/helm.gpg';
multipass exec -n cp01 -- sudo bash -c 'echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee /etc/apt/sources.list.d/helm-stable-debian.list';
multipass exec -n cp01 -- sudo bash -c 'apt-get update';
multipass exec -n cp01 -- sudo bash -c 'apt-get install helm';
multipass exec -n cp01 -- sudo bash -c 'apt-mark hold helm';
# install cilium; cp01 only
multipass exec -n cp01 -- bash -c 'helm repo add cilium https://helm.cilium.io/';
multipass exec -n cp01 -- bash -c 'helm install cilium cilium/cilium --version 1.18.1 --namespace kube-system';

# verify cilium; cp01 only
multipass exec -n cp01 -- bash -c 'CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) && if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} && sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum && sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin';

# multipass exec -n cp01 -- bash -c 'cilium status --wait';

# join workers to cluster
export JOIN_COMMAND=$(multipass exec -n cp01 -- bash -c 'kubeadm token create --print-join-command');

## worker01
multipass exec -n worker01 -- sudo bash -c "${JOIN_COMMAND}";

## worker02
multipass exec -n worker02 -- sudo bash -c "${JOIN_COMMAND}";

# move kube config to local filesystem
multipass exec -n cp01 -- bash -c 'cat ~/.kube/config' > local.kubeconfig;

# verify nodes and that local.kubeconfig works
kubectl --kubeconfig=./local.kubeconfig get nodes;