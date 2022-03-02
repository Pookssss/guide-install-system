#!/bin/bash
command_exists() {
        command -v "$@" > /dev/null 2>&1
}

sh_c='sh -c'
if [ "$user" != 'root' ]; then
    if command_exists sudo; then
			sh_c='sudo -E sh -c'
	elif command_exists su; then
			sh_c='su -c'
	else
		exit 1
	fi
fi

if read -t 300 -p "Input IP K8S-Master-01 : " MASTER01 </dev/tty ; then :
else
    echo "Plase input IP K8S-Master-01"
    exit 1
fi

if read -t 300 -p "Input IP K8S-Master-02 : " MASTER02 </dev/tty ; then :
else
    echo "Plase input IP K8S-Master-02"
    exit 1
fi

if read -t 300 -p "Input IP K8S-Master-03 : " MASTER03 </dev/tty ; then :
else 
    echo "Plase input IP K8S-Master-03"
    exit 1
fi

# upgrade system
$sh_c "apt-get update -qq && apt-get upgrade -y"

# Force Load modules and setting sysctl
$sh_c "cat << EOF >> /etc/modules-load.d/k8s.conf
br_netfilter
EOF"

$sh_c "cat << EOF >> /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF"
$sh_c "sysctl --system > /dev/null"

# install ntp client
$sh_c "apt-get install -qq -y ntpdate >/dev/null"
$sh_c "ntpdate -u time1.nimt.or.th >/dev/null"
$sh_c 'crontab -l | { cat; echo "30 3 * * * ntpdate -u time1.nimt.or.th"; } | crontab -'

# install docker
$sh_c "apt-get install -qq ca-certificates curl gnupg lsb-release > /dev/null"
$sh_c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null"
$sh_c 'echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null'
$sh_c "apt-get update -qq > /dev/null"
$sh_c "apt-get install -qq docker-ce docker-ce-cli containerd.io > /dev/null"

#$sh_c "curl https://get.docker.com | bash >/dev/null"
$sh_c "systemctl enable docker >/dev/null"

# docker daemon config for systemd from cgroupfs & restart (For K8S > 1.22.0)
$sh_c 'cat << EOF >> /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]}
}
EOF'
$sh_c "systemctl daemon-reload && systemctl restart docker"
# DEBUG docker system driver
#$sh_c "docker system info | grep -i driver"

# install k8s
$sh_c "curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg"
$sh_c 'echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list >/dev/null'
$sh_c "apt-get update -qq >/dev/null"
$sh_c "apt-get install -qq -y kubelet kubeadm kubectl nginx >/dev/null"
$sh_c "apt-mark hold kubelet kubeadm kubectl >/dev/null"

# config local lb for kube-api
$sh_c "cat << EOF >> /etc/nginx/nginx.conf
stream {
    upstream kubernetes {
        least_conn;
        server $MASTER01:6443;
        server $MASTER02:6443;
        server $MASTER03:6443;
    }

    access_log off;
    error_log  /var/log/nginx/kubernetes_error.log;

    server {
        listen localhost:10443;
        proxy_pass kubernetes;
        proxy_timeout 10m;
        proxy_connect_timeout 1s;
    }
}
EOF"

$sh_c "cat << EOF >> /etc/nginx/conf.d/zabbix_status.conf
server {
        listen          localhost:80;
        server_name     localhost;

        access_log off;
        error_log off;

        location = /basic_status {
        stub_status;
        access_log   off;
        }

}
EOF"
$sh_c "rm -rf /etc/nginx/sites-enabled/default && rm -rf /etc/nginx/sites-available/default"
$sh_c "systemctl restart nginx"

# install glusterfs client
$sh_c "add-apt-repository -y ppa:gluster/glusterfs-9 >/dev/null"
$sh_c "apt-get install -qq -y glusterfs-client >/dev/null"

# disable swap
$sh_c "sed -i '/swap/d' /etc/fstab"
$sh_c "swapoff -a"