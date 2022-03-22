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


$sh_c "wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.20.0/blackbox_exporter-0.20.0.linux-amd64.tar.gz"

$sh_c "tar xvzf blackbox_exporter-0.14.0.linux-amd64.tar.gz"

$sh_c "cp blackbox_exporter /usr/local/bin"

$sh_c "sudo mkdir -p /etc/blackbox"

$sh_c "cp blackbox.yml /etc/blackbox"

$sh_c "useradd -rs /bin/false blackbox"

$sh_c "chown blackbox:blackbox /usr/local/bin/blackbox_exporter"

$sh_c "chown -R blackbox:blackbox /etc/blackbox/*"

$sh_c "cat << EOF >> /lib/systemd/system/blackbox.service
[Unit]
Description=Blackbox Exporter Service
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=blackbox
Group=blackbox
ExecStart=/usr/local/bin/blackbox_exporter \
  --config.file=/etc/blackbox/blackbox.yml \
  --web.listen-address=":9115"

Restart=always

[Install]
WantedBy=multi-user.target
EOF"

$sh_c "systemctl enable blackbox.service"

$sh_c "systemctl start blackbox.service"

$sh_c "curl http://localhost:9115/metrics"