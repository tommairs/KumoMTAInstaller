# KumoMTA Installer
### A custom installer script for KumoMTA ###

*************************************************************************************************
** PLEASE NOTE THIS IS NOT OFFICIALLY SUPPORTED CODE **

** This is provided as an example so that you may create your own installer for your own environment

** Use this at your own risk
*************************************************************************************************

This project provides a simple, canned installer for typical situations.  It was created for personal use and may not be actively maintained. Use at your own discretion.

Maintainer is [Tom Mairs](https://github.com/tommairs) and he is solely responsible for this code.

The SINK policy will listen for incoming mail on port 25, log it and destroy it.  No outbound mail is permitted.  Its only purpose is to consume and destroy email to act as a backstop for testing high-volume email services.

The SEND policy is a typical basic sending profile complete with TLS, DKIM, custom routing, and other customizations.

## INSTALL ##
*The general steps are:*
 - Build an AWS/Azure/GCP server instance with at least 2 cores, 8Gb RAM, and 20GB Storage
 - Select a security group only allowing port 25, 587, 22, 2025, 8000
 - Before going further, create a resolvable domain in DNS
 - Clone this repo to that server

With DNF (AMZN2023, CentOS, Rocky, Alma, etc):
```console
sudo dnf install -y git
```
With apt (Debian, Ubuntu, etc):
```console
sudo apt install -y git
```
Then:
```console
cd
git clone https://github.com/KumoCorp/KumoMTAInstaller.git
cd KumoMTAInstaller
```

Review and modify ```manifest.txt``` with any preset variable data if needed. 

```console
vi manifest.txt
```

Then execute the installer with bash (not sh).

```console
bash kinstaller.sh
```
 - follow all the prompts
  - When finished, you can test the Transmissions API with a `sh curltest.json` which will send a generic mail to th eaddress defined as "Owner" in the manifest file.
  - or run telnet localhost 25 and paste the contents of telnettest.txt

 Any specific instructions are buried in the script and are typically exposed as part of the Bash script.
 There is very little (if any) field validation so be precise in your answers.
 
 Note that the systemd and environment files are not added automatically. They are there for your convenience to add manually if needed.
 
## Validations
This script has been tested succesfully with: 
* Ubuntu 20, 22, 24
* Rocky 9
 

