#!/bin/bash

# prompt for username
echo "A user will be created and be given shell login permission."
echo "This user will be added to the docker group."
echo "Then root login will be disabled and password login will be disabled."
echo "Only ssh key login will be allowed."
echo "You will need your ssh public key to continue."
echo "Please enter your ssh username:"
read username

# prompt for public ssh key
echo "Please enter the public ssh key for $username:"
echo "to generate a key pair, run 'ssh-keygen -t rsa -b 4096 -C \"
$username@$(hostname)\"'"
echo "then copy the contents of the public key file (usually you can run: cat ~/.ssh/id_rsa.pub)"
echo "and paste it here."

read ssh_key

# create user
sudo useradd -m -s /bin/bash $username
sudo usermod -aG docker $username

# create a strong random password for $username and save password
user_password=$(openssl rand -base64 32)
echo "$username:$user_password" | sudo chpasswd

# disable password login for $username. only allow ssh key login
sudo sed -i 's/^$username:.*$/$username:*:18493:0:99999:7:::/g' /etc/shadow

# configure ssh server to disallow password login
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
# disable root login
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

# install $username sshkey
sudo mkdir -p /home/$username/.ssh
echo $ssh_key | sudo tee /home/$username/.ssh/authorized_keys
sudo chown -R $username:$username /home/$username/.ssh
sudo chmod 700 /home/$username/.ssh
sudo chmod 600 /home/$username/.ssh/authorized_keys

# install docker  https://docs.docker.com/engine/install/debian/

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

# add $username to docker group
sudo usermod -aG docker $username

# start docker and configure docker to start on boot
sudo service docker start

sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# install kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc






echo "Installed Docker and kubernetes"
echo "You may now logout of root and login as $username"
echo "Then run 'kubernetes start' to start kubernetes"

