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



# upgrade system
$sh_c "wget https://github.com/prometheus/prometheus/releases/download/v2.32.1/prometheus-2.32.1.linux-amd64.tar.gz"

$sh_c "tar -xvf prometheus-2.32.1.linux-amd64.tar.gz"

$sh_c "mv prometheus-2.32.1.linux-amd64 prometheus-files"


$sh_c "useradd --no-create-home --shell /bin/false prometheus"
$sh_c "mkdir /etc/prometheus"
$sh_c "mkdir /var/lib/prometheus"
$sh_c "chown prometheus:prometheus /etc/prometheus"
$sh_c "chown prometheus:prometheus /var/lib/prometheus"
$sh_c "cp prometheus-files/prometheus /usr/local/bin/"
$sh_c "cp prometheus-files/promtool /usr/local/bin/"
$sh_c "chown prometheus:prometheus /usr/local/bin/prometheus"
$sh_c "chown prometheus:prometheus /usr/local/bin/promtool"
$sh_c "cp -r prometheus-files/consoles /etc/prometheus"
$sh_c "cp -r prometheus-files/console_libraries /etc/prometheus"
$sh_c "chown -R prometheus:prometheus /etc/prometheus/consoles"
$sh_c "chown -R prometheus:prometheus /etc/prometheus/console_libraries"





$sh_c "cat << EOF >> /etc/prometheus/prometheus.yml
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']

EOF"

$sh_c "chown prometheus:prometheus /etc/prometheus/prometheus.yml"

$sh_c "cat << EOF >> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF"



$sh_c "systemctl daemon-reload"
$sh_c "systemctl start prometheus"
$sh_c "systemctl status prometheus"