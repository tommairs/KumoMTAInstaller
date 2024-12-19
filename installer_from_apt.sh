#!/bin/bash

###############################################
# Installer to build KumoMTA as a sink server
# This set of instructions installs from APT
###############################################

# Prep first
# Build an AWS t2.medium (2CPU, 4Gb RAM) with Ubuntu20 - This is the smallest, cheapest build possible and might run you a-buck-a-day to keep operational. 
# The AMI used for this script is ami-0672af4b5c29cece0
# Make sure you create a security group that allows inbound port 25
# Increase the storage volume to 20Gb to accomodate logging.
# Now login and do the basic OS cleanup and add some helpful packages

sudo apt-get autoclean
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt install -y firewalld tree telnet git bind9 bind9-utils vim jq

sudo systemctl start named
sudo systemctl enable named


# Make sure it all stays up to date. Run a dnf update at 3AM daily
# This version also uses the AL2 specific cron.daily location
sudo echo "0 3 * * * root /usr/bin/apt-get update -y; /usr/bin/apt-get upgrade -y >/dev/null 2>&1" | sudo tee /etc/cron.daily/apt-updates >/dev/null

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


# This is the part that actually installs KumoMTA

UVER=`cat /etc/os-release |grep VERSION_ID | awk  '{print $1}' | awk -F '"' '{print $2}' | awk -F '.' '{print $1}'`

#If this is V24...
if [ "$UVER" == "24" ]; then
sudo apt install -y curl gnupg ca-certificates
curl -fsSL https://openrepo.kumomta.com/kumomta-ubuntu-22/public.gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/kumomta.gpg
curl -fsSL https://openrepo.kumomta.com/files/kumomta-ubuntu22.list | sudo tee /etc/apt/sources.list.d/kumomta.list > /dev/null
sudo apt update
sudo apt install -y kumomta
fi


#If this is V22...
if [ "$UVER"  == "22" ]; then
sudo apt install -y curl gnupg ca-certificates
curl -fsSL https://openrepo.kumomta.com/kumomta-ubuntu-22/public.gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/kumomta.gpg
curl -fsSL https://openrepo.kumomta.com/files/kumomta-ubuntu22.list | sudo tee /etc/apt/sources.list.d/kumomta.list > /dev/null
sudo apt update
sudo apt install -y kumomta
fi


#If this is V20...
if [ "$UVER" == "20" ]; then
sudo apt install -y curl gnupg ca-certificates
curl -fsSL https://openrepo.kumomta.com/kumomta-ubuntu-20/public.gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/kumomta.gpg
curl -fsSL https://openrepo.kumomta.com/files/kumomta-ubuntu20.list | sudo tee /etc/apt/sources.list.d/kumomta.list > /dev/null
sudo apt update
sudo apt install -y kumomta-dev
fi


# EOF
