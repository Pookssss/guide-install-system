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

$sh_c "wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz"

$sh_c "tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz"

$sh_c "cp node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/"


$sh_c "useradd -rs /bin/false node_exporter"



$sh_c "cat << EOF >> /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF"


$sh_c "systemctl daemon-reload"
$sh_c "systemctl start node_exporter"
$sh_c "systemctl enable node_exporter"
$sh_c "systemctl status node_exporter"