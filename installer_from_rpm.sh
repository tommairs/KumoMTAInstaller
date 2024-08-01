#!/bin/bash

###############################################
# Installer to build KumoMTA as a sink server
# This set of instructions installs from the RPM
###############################################

# Prep first
# Build an AWS t2.medium (2CPU, 4Gb RAM) with Rocky9 - This is the smallest, cheapest build possible and might run you a-buck-a-day to keep operational. 
# The AMI used for this script is ami-0672af4b5c29cece0
# Make sure you create a security group that allows inbound port 25
# Increase the storage volume to 20Gb to accomodate logging.
# Now login and do the basic OS cleanup and add some helpful packages

sudo dnf clean all
sudo dnf update -y
sudo dnf install -y firewalld tree telnet git bind bind-utils 
sudo dnf install -y mlocate cronie gcc make gcc-c++ clang vim-enhanced

sudo systemctl start named
sudo systemctl enable named

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
sudo firewall-cmd --zone=public --permanent --add-port=2026/tcp

sudo systemctl enable firewalld
sudo firewall-cmd --reload


# This is the part that actually installs KumoMTA
OSNAME=`cat /etc/os-release |grep -Po '(?<=PRETTY_NAME\=")[^["]*\s'`
echo "This is actually" $OSNAME


if [ "$OSNAME"=="Rocky Linux" ]; then
# IF this is Rocky, then....
echo "Installing KumoMTA for " $OSNAME
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
    --add-repo \
    https://openrepo.kumomta.com/files/kumomta-rocky.repo
sudo yum install -y kumomta-dev
sudo cp init.lua /opt/kumomta/etc/policy/
fi

if [ "$OSNAME"=="Amazon Linux" ]; then
# IF this is AMZN 2023, then....
echo "Installing KumoMTA for " $OSNAME
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo  https://openrepo.kumomta.com/files/kumomta-amazon2023.repo
sudo yum install -y kumomta-dev
sudo cp init.lua /opt/kumomta/etc/policy/
fi




# This will run KumoMTA as sudo (to access port 25) and push it to the background
#sudo KUMOD_LOG=kumod=info /opt/kumomta/sbin/kumod --policy /opt/kumomta/etc/policy/${POLICYTYPE}.lua --user kumod&

sudo systemctl start kumomta
sudo systemctl enable kumomta


# EOF
