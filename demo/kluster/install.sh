#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
swapoff -a
perl -p -i -e "s/.*swap.*/#/g" /etc/fstab
ufw disable
apt-get update
apt-get install -y docker.io
systemctl enable docker.service
usermod -aG docker vagrant
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update && apt-get install -y kubelet kubeadm kubectl
echo "install.sh done"