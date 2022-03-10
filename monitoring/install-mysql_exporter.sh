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

$sh_c "wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.12.1/mysqld_exporter-0.12.1.linux-amd64.tar.gz"

$sh_c "tar xvfz mysqld_exporter-*.*-amd64.tar.gz"

$sh_c "sudo cp  mysqld_exporter-*.linux-amd64/mysqld_exporter /usr/local/bin/"


$sh_c "sudo groupadd --system prometheus"

$sh_c "sudo chmod +x /usr/local/bin/mysqld_exporter"

$sh_c "mysql -u root -e 'CREATE USER '\''exporter'\''@'\''localhost'\'' IDENTIFIED BY '\''PassW0rd'\'' WITH MAX_USER_CONNECTIONS 2 '\' '"

$sh_c "mysql -u root -e 'GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO '\''exporter'\''@'\''localhost'\'''"

$sh_c "mysql -u root -e 'FLUSH PRIVILEGES'"

$sh_c "export DATA_SOURCE_NAME='exporter:PassW0rd@(localhost:3306)/'"

$sh_c "cat << EOF >> /etc/.mysqld_exporter.cnf
[client]
user=exporter
password=PassW0rd
EOF"

$sh_c "sudo chown root:prometheus /etc/.mysqld_exporter.cnf"

$sh_c "cat << EOF >> /etc/systemd/system/mysql_exporter.service
[Unit]
Description=Prometheus MySQL Exporter
After=network.target
User=prometheus
Group=prometheus

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter \
--config.my-cnf /etc/.mysqld_exporter.cnf \
--collect.global_status \
--collect.info_schema.innodb_metrics \
--collect.auto_increment.columns \
--collect.info_schema.processlist \
--collect.binlog_size \
--collect.info_schema.tablestats \
--collect.global_variables \
--collect.info_schema.query_response_time \
--collect.info_schema.userstats \
--collect.info_schema.tables \
--collect.perf_schema.tablelocks \
--collect.perf_schema.file_events \
--collect.perf_schema.eventswaits \
--collect.perf_schema.indexiowaits \
--collect.perf_schema.tableiowaits \
--collect.slave_status \
--web.listen-address=0.0.0.0:9104

[Install]
WantedBy=multi-user.target
EOF"

$sh_c "systemctl daemon-reload"

$sh_c "systemctl enable mysql_exporter"

$sh_c "systemctl start mysql_exporter"