#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# configure docker to start on boot
sudo systemctl enable docker
sudo service docker start

# create my user
sudo useradd -m -s /bin/bash jdobson
sudo usermod -aG docker jdobson

# create a strong random password for jdobson and save password
jdobson_password=$(openssl rand -base64 32)
echo "jdobson:$jdobson_password" | sudo chpasswd

# disable password login for jdobson. only allow ssh key login
sudo sed -
i 's/^jdobson:.*$/jdobson:*:18493:0:99999:7:::/g' /etc/shadow

# configure ssh server to disallow password login
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

# install jdobson sshkey
sudo mkdir /home/jdobson/.ssh
sudo cp /root/.ssh/authorized_keys /home/jdobson/.ssh/authorized_keys
sudo chown -R jdobson:jdobson /home/jdobson/.ssh
sudo chmod 700 /home/jdobson/.ssh
sudo chmod 600 /home/jdobson/.ssh/authorized_keys




