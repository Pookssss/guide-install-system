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
$sh_c "sudo apt-get install -y adduser libfontconfig1"
$sh_c "wget https://dl.grafana.com/enterprise/release/grafana-enterprise_8.3.3_amd64.deb"

$sh_c " dpkg -i grafana-enterprise_8.3.3_amd64.deb"


$sh_c "systemctl daemon-reload"
$sh_c "systemctl start grafana-server"
$sh_c "systemctl status grafana-server"
$sh_c "systemctl enable grafana-server.service"
