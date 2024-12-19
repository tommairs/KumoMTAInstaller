#!/bin/bash

clear
echo "*****************************************************"
echo "* KumoMTA Installer (not official)                   "
echo "*                                                    "
echo "* Run this as bash kinstaller.sh NOT with sh         "
echo "* Works properly with Ubuntu 22, 20, 24              "
echo "*     Rocky 9, Alma 9, RHEL 9                        "
echo "* Edit manifest.txt first for automated install      "
echo "*****************************************************"


echo "Press any key to continue.  CTRL-C to escape"
read

FILE=`find -path "./manifest.txt"`
if [ "$FILE" != "" ]; then
  echo "Found a manifest to load, continuing with that"
  source $FILE
fi

    if [ -z "$DOMAIN" ]; then
    echo "Enter the Sending Domain for DKIM signing  (IE: \"e.myserver.net\") or press ENTER/RETURN for default" 
    read MYFQDN
  fi

  if [ -z "$SELECTOR" ]; then
    echo "Enter the DKIM Selector id for DNS (IE: \"dkim1024\") or press ENTER/RETURN for default" 
    read MYFQDN
  fi
  
  if [ -z "$POLICYTYPE" ]; then
    echo "What type of install do you want, SEND or SINK?"
    read POLICYTYPE
  fi 

  if [ -z "$INSTALLTYPE" ]; then
    echo "What type of package manager, dnf or apt?"
    read INSTALLTYPE
  fi
 
bash ./cert_builder.sh

sudo hostnamectl set-hostname $MYFQDN
export PUBLICIP=`curl -s checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//' `
export PRIVATEIP=`hostname -i`

sudo echo "
$PRIVATEIP  $HOSTNAME
$PUBLICIP $MYFQDN" |sudo tee -a /etc/hosts

# Use SSH keys only
echo "
## Configure for pubkey only logins
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
" |sudo tee -a /etc/ssh/sshd_config

#Modify and save the MOTD banner
sudo cp motd.txt /etc/motd -rf
sudo cp motd.sh /etc/motd.sh -rf
echo "sh /etc/motd.sh" >> ~/.profile
#echo "sh /etc/motd.sh" >> ~/.bashrc

cat "                $FNAME
------------------------------------------------" >> /etc/motd

sudo sed -i "s/    Kumo Sink/$FNAME/" /etc/motd
sudo sed -i "s/Rocky 9/$SSLDIR/" /etc/motd

##########################################################
# Check to see if this is actual RHEL
export ISRH=`cat /etc/redhat-release`
if [[ "$ISRH" == *"Red Hat Enterprise"* ]]; then
    echo "This looks like Red Hat Enterprise Linux."
    
    if [ "$RH_USER_NAME" == "" ]; then
    echo "What is your registered RedHat Username?"
    read RH_USER_NAME
  fi 
    if [ "$RH_PASSWORD" == "" ]; then
    echo "What is your RedHat User Password?"
    read RH_PASSWORD
    fi
else
    echo "Looks like this is not RHEL, continuing without subscription manager."
    export RH_USER_NAME="NONE"
fi
##########################################################



# Modify sysctl with friendly values
sudo echo "
vm.max_map_count = 768000
net.core.rmem_default = 32768
net.core.wmem_default = 32768
net.core.rmem_max = 262144
net.core.wmem_max = 262144
fs.file-max = 250000
net.ipv4.ip_local_port_range = 5000 63000
net.ipv4.tcp_tw_reuse = 1
kernel.shmmax = 68719476736
net.core.somaxconn = 4096
vm.nr_hugepages = 10
kernel.shmmni = 4096 " | sudo tee -a /etc/sysctl.d/kumo-sysctl.conf

sudo /sbin/sysctl -p /etc/sysctl.d/kumo-sysctl.conf

# Kill off services that may be preinstalled and will interfere
sudo systemctl stop  postfix.service
sudo systemctl disable postfix.service

sudo systemctl stop  qpidd.service
sudo systemctl disable qpidd.service

# Determine which installer to run
PKGTYPE=`cat /etc/os-release |grep ^NAME`

if [ "$PKGTYPE" == "Rocky Linux" ]; then
        echo "Running DNF installer"
        source './installer_from_rpm.sh'
elif [ "$PKGTYPE" == "Ubuntu" ]; then
        echo "Running APT installer"
        source './installer_from_apt.sh'
elif [ $INSTALLTYPE == "dnf" ];then
        echo "Continuing with DNF installer"
        source './installer_from_rpm.sh'
elif [ "$INSTALLTYPE" == "apt" ]; then
        echo "Continuing with APT installer"
        source './installer_from_apt.sh'
else
        # Unknown
        echo "Unknown OS.  Run APT or RPM installer manually"
fi

# Build a DKIM key for your sending domain
sudo mkdir -p /opt/kumomta/etc/dkim/$DOMAIN
sudo openssl genrsa -out /opt/kumomta/etc/dkim/$DOMAIN/$SELECTOR.key 1024
sudo openssl rsa -in /opt/kumomta/etc/dkim/$DOMAIN/$SELECTOR.key -out /opt/kumomta/etc/dkim/$DOMAIN/$SELECTOR.pub -pubout -outform PEM

sudo echo "
syntax on" |sudo tee -a ~/.vimrc 

sudo systemctl enable kumomta
sudo systemctl start kumomta

sudo systemctl enable kumo-tsa-daemon
sudo systemctl start kumo-tsa-daemon

echo
echo "Installation of KumoMTA complete"
echo

# Optionally test it...
telnet localhost 25

