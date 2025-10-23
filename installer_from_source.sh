#!/bin/bash

###############################################
# Installer to build KumoMTA as a sink server
#
###############################################

# Prep first
# Build an AWS t2.medium (2CPU, 4Gb RAM) with Rocky9 - This is the smallest, cheapest build possible and might run you a-buck-a-day to keep operational. 
# The AMI used for this script is ami-0672af4b5c29cece0
# Make sure you create a security group that allows inbound port 25
# Increase the storage volume to 20Gb to accomodate logging.
# Now login and do the basic OS cleanup and add some helpful packages

sudo dnf clean all
sudo dnf update -y
sudo dnf upgrade -y
sudo dnf install -y firewalld tree telnet git bind bind-utils 
sudo dnf install -y plocate cronie gcc make gcc-c++ clang vim-enhanced

# Make sure it all stays up to date. Run a dnf update at 3AM daily
# This version also uses the AL2 specific cron.daily location
sudo echo "0 3 * * * root /usr/bin/dnf update -y >/dev/null 2>&1" | sudo tee /etc/cron.daily/dnf-updates >/dev/null

# Build a basic firewall
sudo echo "ZONE=public
" | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0

sudo systemctl stop firewalld
sudo systemctl start firewalld.service
sudo firewall-cmd --set-default-zone=public
sudo firewall-cmd --zone=public --change-interface=eth0
sudo firewall-cmd --zone=public --permanent --add-service=http
sudo firewall-cmd --zone=public --permanent --add-service=https
sudo firewall-cmd --zone=public --permanent --add-service=ssh
sudo firewall-cmd --zone=public --permanent --add-service=smtp
sudo firewall-cmd --zone=public --permanent --add-port=587/tcp

sudo systemctl enable firewalld
sudo firewall-cmd --reload

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.profile
source ~/.cargo/env
rustc -V

# Redis is not included in Rocky 10, so we need to build it from source
sudo yum -y install gcc make
cd /usr/local/src
sudo wget http://download.redis.io/redis-stable.tar.gz
sudo tar xvzf redis-stable.tar.gz
sudo rm -f redis-stable.tar.gz
cd redis-stable
sudo make
sudo make install

# Build from source since there is not AL2 rpm
cd 
git clone https://github.com/kumomta/kumomta.git

# Pause here to provide credentials
cd kumomta

#Also remove redis install from get-deps.sh
sed -i "s/    'redis'//" get-deps.sh

./get-deps.sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env
cargo build --release

# This is no longer necessary 
#sudo assets/install.sh /opt/kumomta

# Now build out some infra that is not in the RPM

getent group kumod >/dev/null || groupadd --system kumod
getent passwd kumod >/dev/null || \
    useradd --system -g kumod -d /var/spool/kumod -s /sbin/nologin \
    -c "Service account for kumomta" kumod
for dir in /var/spool/kumomta /var/log/kumomta ; do
  [ -d "\$dir" ] || install -d --mode 2770 --owner kumod --group kumod \$dir
done


#sudo useradd -U -M kumod
#sudo mkdir -p /var/log/kumo
#sudo mkdir -p /var/spool/kumo/data
#sudo mkdir -p /var/spool/kumo/meta
sudo mkdir -p /opt/kumomta/etc/policy
chown kumod:kumod /opt/kumomta/etc/policy
cp sink.lua /opt/kumomta/etc/policy/



#
## This seems broken
#sudo chown root:rocky /var/spool/kumo -R
#sudo chmod 775 /var/spool/kumo/ -R

# This will run KumoMTA as sudo (to access port 25) and push it to the background
sudo /opt/kumomta/sbin/kumod --policy /opt/kumomta/etc/policy/tomtest.lua --user kumod&

