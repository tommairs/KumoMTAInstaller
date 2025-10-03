#!/bin/bash

echo "Alternate Cert Builder"
echo


FILE=`find -path "./manifest.txt"`
if [ "$FILE" != "" ]; then
  echo "Found a manifest to load, continuing with that"
  source ./manifest.txt
fi


  if [ -z "$MYFQDN" ]; then
    echo "Enter the FQDN  (IE: \"myserver.home.net\") or press ENTER/RETURN for default" 
    read MYFQDN
  fi
  
    if [ -z "$DOMAIN" ]; then
    echo "Enter the Sending Domain for DKIM signing  (IE: \"e.myserver.net\") or press ENTER/RETURN for default" 
    read DOMAIN
  fi

  if [ -z "$SELECTOR" ]; then
    echo "Enter the DKIM Selector id for DNS (IE: \"dkim1024\") or press ENTER/RETURN for default" 
    read SELECTOR
  fi

   if [ -z "$CERT_CO" ]; then
    echo "For the certificate, what country code are you in? (CA,US,UK, etc)"
    read CERT_CO
  fi

  if [ -z "$CERT_ST" ]; then
    echo "For the certificate, what State or Province are you in? (Alberta, California, etc)"
    read CERT_ST
  fi 
  
  if [ -z "$CERT_LO" ]; then
    echo "For the certificate, what city are you in? (Edmonton, Houston, etc)"
    read CERT_LO
  fi 
  
  if [ -z "$CERT_ORG" ]; then
    echo "For the certificate, what is the name of your company or organization"
    read CERT_ORG
  fi 
  
  if [ -z "$POLICYTYPE" ]; then
    echo "What type of install do you want, SEND or SINK?"
    read POLICYTYPE
  fi 
  
  if [ -z "$SSLDIR" ]; then
    echo "What platform are we building SSL certificates for? "
    echo "Valid terms are Ubuntu, Debian, Centos, Rocky.  Pick the closest one"
    read SSLDIR
  fi 


# create v3.ext file
cat "authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
" > v3.ext

# Generate private key 
openssl genrsa -out ca.key 2048 

# Generate CSR 
#openssl req -new -key ca.key -out ca.csr           
openssl req -new -key ca.key -out ca.csr -subj "/C=$CERT_CO/ST=$CERT_ST/L=$CERT_LO/O=$CERT_ORG/CN=$MYFQDN/"

# Generate Self Signed Key
# (old) openssl x509 -req -days 365 -in ca.csr -signkey ca.key -out ca.crt
openssl x509 -req -days 365 -in ca.csr -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -out ca.crt

# Copy the files to the correct locations

# Note this is /etc/ssl/ for Ubuntu/Debian
# Note this is /etc/pki/tls/ for CentOS/Rocky
# Note this is /opt/kumomta/etc/tls/ for KumoMTA Specific



if [ $SSLDIR == "Ubuntu" ] || [ $SSLDIR == "Debian" ]; then
  sudo mkdir -p /etc/ssl/$DOMAIN
  sudo cp -f ca.crt /etc/ssl/$DOMAIN
  sudo cp -f ca.key /etc/ssl/$DOMAIN
  sudo cp -f ca.csr /etc/ssl/$DOMAIN
  fi

if [ $SSLDIR == "Apache" ] || [ $SSLDIR == "Centos" ] || [ $SSLDIR == "Rocky" ]; then
  sudo mkdir -p /etc/pki/tls/private/$DOMAIN
  sudo mkdir -p /etc/pki/tls/certs/$DOMAIN
  sudo cp -f ca.crt /etc/pki/tls/certs/$DOMAIN
  sudo cp -f ca.key /etc/pki/tls/private/$DOMAIN
  sudo cp -f ca.csr /etc/pki/tls/private/$DOMAIN
  sed -i 's/SSLCertificateFile \/etc\/pki\/tls\/certs\/localhost.crt/SSLCertificateFile \/etc\/pki\/tls\/certs\/ca.crt/' /etc/httpd/conf.d/ssl.conf
  sed -i 's/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/localhost.key/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/ca.key/' /etc/httpd/conf.d/ssl.conf
fi

  sudo mkdir -p /opt/kumomta/etc/tls/$DOMAIN
  sudo mv -f ca.crt /opt/kumomta/etc/tls/$DOMAIN
  sudo mv -f ca.key /opt/kumomta/etc/tls/$DOMAIN
  sudo mv -f ca.csr /opt/kumomta/etc/tls/$DOMAIN

  sudo chmod 644 /opt/kumomta/etc/tls/$DOMAIN/ca.*
  sudo chown root:root /opt/kumomta/etc/tls/$DOMAIN/ca.*

echo
echo "Certificate build complete"
echo
