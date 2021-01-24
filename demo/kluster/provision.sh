#!/usr/bin/env bash

hostname=$(hostname)
set +e 
function install_system() {
    export DEBIAN_FRONTEND=noninteractive
    swapoff -a
    perl -p -i -e "s/.*swap.*/#/g" /etc/fstab
    ufw disable
    apt-get update
    apt-get install -y containerd
    mkdir -p /etc/containerd
    # configure containerd, override runtime and setup local image registry for http
    # sed -re 's/(\s+)\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc\]$/\0\n\1  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]\n\1     SystemdCgroup = true/' \
    containerd config default | \
        sed -re 's#(\s+)\[plugins."io.containerd.grpc.v1.cri".registry.mirrors]$#\0\n\1  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.56.1:5000"]\n\1    endpoint = ["http://192.168.56.1:5000"]#' \
        > /etc/containerd/config.toml
    systemctl restart containerd
    cp /etc/containerd/config.toml /vagrant/tmp/config.toml
    apt-get update && apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    echo deb http://apt.kubernetes.io/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list
    apt-get update && apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
    mkdir -p /vagrant/tmp
    echo "install done"
}

function prepare_kernel() {
    printf "%s\n" br_netfilter > /etc/modules-load.d/k8s.conf
    modprobe br_netfilter

    printf "%s = 1\n" net.ipv4.ip_forward net.bridge.bridge-nf-call-ip6tables net.bridge.bridge-nf-call-iptables > /etc/sysctl.d/k8s.conf

    sysctl --system
    systemctl daemon-reload
    systemctl restart kubelet
}

function install_cni() {
    su - -c ' \
        kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml; \
        kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml' \
    vagrant
}

function append_log() {
    xargs -l -0 -I{} echo [$(date)] {} | tee -a /vagrant/tmp/$hostname.log
}

base_ip=$(grep 192 /vagrant/Vagrantfile | sed 's/[^0-9,\.]//g' | cut -f2 -d,)
this_ip=$(ifconfig | grep $base_ip| sed -e 's/\s\s*/ /g' | cut -f 3 -d ' ')

# install
echo installing $hostname | append_log
install_system 2>&1 

# ensure 192.168.56 network is being used
echo KUBELET_EXTRA_ARGS=--node-ip=$this_ip > /etc/default/kubelet
printf "Post install\n********************************************\n" | append_log
prepare_kernel 2>&1 | append_log
if [ "$hostname" = "master" ]; then
    # Remove old post install script if present
    rm /vagrant/tmp/join.sh 2> /dev/null

    # Update configuration to match our system
    kubeadm config print init-defaults --component-configs KubeletConfiguration | \
        sed -re "s#(advertiseAddress:).*#\1 $this_ip#" | \
        sed -re "s#(criSocket:).*#\1 /run/containerd/containerd.sock#" | \
        sed -re 's#(\s+)serviceSubnet.*#\0\n\1podSubnet: 192.168.0.0/16#g' > /vagrant/tmp/cfg.yml
    # Apprend cgroup driver spec
    echo cgroupDriver: systemd >> /vagrant/tmp/cfg.yml
    # initialize cluster
    kubeadm init --config /vagrant/tmp/cfg.yml 2>&1 | append_log
    # setup kubectl for master node for vagrant user
    su - -c ' \
        mkdir -p $HOME/.kube; \
        sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config; \
        sudo chown $(id -u):$(id -g) $HOME/.kube/config; \
        kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml' \
    vagrant 2>&1 | append_log
    # export .kube_config to host 
    cp /etc/kubernetes/admin.conf /vagrant/tmp/.kube_config  2>&1 | append_log
    # install calico as a CNI plugin
    install_cni 2>&1 | append_log
    # generate and setup join script
    echo $(kubeadm token create --print-join-command) --cri-socket /run/containerd/containerd.sock > /vagrant/tmp/join.sh
else
    # wait until join has been created
    while [ ! -f /vagrant/tmp/join.sh ]; do
        sleep 2;
    done
    # run join cmd
    sh -x /vagrant/tmp/join.sh
fi
echo $hostname ready 2>&1 | append_log
