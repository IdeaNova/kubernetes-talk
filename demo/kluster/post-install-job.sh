#!/bin/sh
base_ip=`grep 192 /vagrant/Vagrantfile | sed 's/[^0-9,\.]//g' | cut -f2 -d,`
if [ "$(hostname)" = "master" ]; then
    rm /vagrant/join.sh 2>&1 > /vagrant/master.log
    sysctl net.bridge.bridge-nf-call-iptables=1 2>&1 >> /vagrant/master.log
    kubeadm init --ignore-preflight-errors=NumCPU --apiserver-advertise-address=${base_ip}0 --pod-network-cidr=10.244.0.0/16  2>&1 | tee -a /vagrant/master.log | perl -p -e 's/\\\n//' | grep kubeadm\ join > /tmp/join.sh;
    su - -c ' \
        mkdir -p $HOME/.kube; \
        sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config; \
        sudo chown $(id -u):$(id -g) $HOME/.kube/config; \
        kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml' \
    vagrant 2>&1 >> /vagrant/master.log
        #kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml;' \

    cp /etc/kubernetes/admin.conf /vagrant/.kube_config  2>&1 >> /vagrant/master.log
    # this seems to be needed on virtualbox to set up routing between master and workers
    for worker in $(seq -f ${base_ip}%g 1 $num_workers); do
        until ping -c1 $worker >/dev/null 2>&1; do :; done
        echo $worker is up >> /vagrant/master.log
    done
    echo KUBELET_EXTRA_ARGS=--node-ip=192.168.56.80 > /etc/default/kubelet
    systemctl daemon-reload
    systemctl restart kubelet
    mv /tmp/join.sh /vagrant 2>&1 >> /vagrant/master.log
else
    echo KUBELET_EXTRA_ARGS=--node-ip=192.168.56.8$(hostname | tr -d a-z) > /etc/default/kubelet
    systemctl daemon-reload
    systemctl restart kubelet
    while [ ! -f /vagrant/join.sh ]; do
        sleep 2;
    done
    sh -x /vagrant/join.sh
fi
echo $(hostname) ready 2>&1 | tee -a /vagrant/master.log