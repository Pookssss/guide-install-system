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

if read -t 300 -p "Input User : " USER </dev/tty ; then :
else
    echo "Plase input User to can use docker"
    exit 1
fi

#Uninstall old versions of Docker
$sh_c "apt-get remove docker docker-engine docker.io containerd runc"


# Step 1 : Install using the repository
$sh_c "apt-get update"

$sh_c "sudo apt-get install ca-certificates curl  gnupg  lsb-release"

$sh_c "sudo mkdir -p /etc/apt/keyrings"

$sh_c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg"

$sh_c 'sudo echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null '

# Step 2 : Install Docker Engine
$sh_c "sudo apt-get update -qq > /dev/null"
       
$sh_c "sudo apt-get install -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin > /dev/null"

$sh_c "sudo groupadd docker"

$sh_c "sudo usermod -aG docker $USER"

$sh_c "sudo chmod 666 /var/run/docker.sock"

$sh_c "docker ps"