#!/bin/bash

# bash script to set minimal security on new installations of Ubuntu
# and CentOS Linux. Written using Ubuntu 20.04 and CentOS 8.
# Written by Ted LeRoy with help from Google and the Linux community
# Follow or contribute on GitHub here:
# https://github.com/TedLeRoy/first-ten-seconds-centos-ubuntu
# Inspired by Jerry Gamblin's post:
# https://jerrygamblin.com/2016/07/13/my-first-10-seconds-on-a-server/

# Defining Colors for text output
red=$( tput setaf 1 );
yellow=$( tput setaf 3 );
green=$( tput setaf 2 );
normal=$( tput sgr 0 );

# Determine OS name and store it in "osName" variable
osName=`cat /etc/*os-release | grep ^NAME | cut -d '"' -f 2`

# Checking if running as root. If yes, asking to change to a non-root user.
# This verifies that a non-root user is configured and is being used to run
# the script.

if [ ${UID} == 0  ]
then
  echo "${red}
  You're running this script as root user.
  Please configure a non-root user and run this
  script as that non-root user.
  Please do not start the script using sudo, but
  enter sudo privileges when prompted.
  ${normal}"
  exit
fi

#################################################
#                 Ubuntu Section                #
#################################################

# If OS is Ubuntu, apply the security settings for Ubuntu

if [ "$osName" == "Ubuntu" ]
then
  echo "${green}  You're running "$osName" Linux. "$osName" security
  first measures will be applied.

  You will be prompted for your sudo password.
  Please enter it when asked.
  ${normal}
  "
  # Enabling ufw firewall and making sure it allows SSH
  echo "${yellow}  Enabling ufw firewall. Ensuring SSH is allowed.
  ${normal}"
  sudo ufw allow ssh
  sudo ufw --force enable
  echo "${green}
  Done configuring ufw firewall.
  ${normal}"
    # Checking whether an authorized_keys file exists in logged in user's account.
    # If so, the assumption is that key based authentication is set up.
    if [ -f /home/$USER/.ssh/authorized_keys ]
    then
      echo "${yellow}  
      Locking down SSH so it will only permit key-based authentication.
      ${normal}"
      echo -n "${red}  
      Are you sure you want to allow only key-based authentication for SSH? 
      PASSWORD AUTHENTICATIN WILL BE DISABLED FOR SSH ACCESS!
      (y or n)${normal}" 
      read answer
      # Putting relevant lines in /etc/ssh/sshd_config.d/11-sshd-first-ten.conf file
      if [ "$answer" == "y" ] ;then
        echo "${yellow}
        Adding the following lines to a file in sshd_config.d
        ${normal}"
        echo "DebianBanner no
DisableForwarding yes
PermitRootLogin no
IgnoreRhosts yes
PasswordAuthentication no
PermitEmptyPasswords no" | sudo tee /etc/ssh/sshd_config.d/11-sshd-first-ten.conf 
        echo "${yellow}
        Reloading ssh
        ${normal}"
	# Restarting ssh daemon
        sudo systemctl reload ssh
        echo "${green}
        ssh has been restarted.
        ${normal}"

      else
	# User chose a key other than "y" for configuring ssh so it will not be set up now
        echo "${red}
        You have chosen not to disable password based authentication at this time.
        Please do so yourself or re-run this script when you're prepared to do so.
        ${normal}"
      fi

  else
    # The check for an authorized_keys file failed so it is assumed key based auth is not set up
    # Skipping this configuration and warning user to do it for herself
    echo "${red}  
    It looks like SSH is not configured to allow key based authentication.
    Please enable it and re-run this script.${normal}"
  fi
  # Installing fail2ban and networking tools (includes netstat)
  echo "${yellow}
  Installing fail2ban and networking tools.
  ${normal}"
  sudo apt install fail2ban net-tools -y
  echo "${green}
  fail2ban and networking tools have been installed.
  ${normal}"
  # Setting up the fail2ban jail for SSH
  echo "${yellow}
  Configuring fail2ban to protect SSH.

  Entering the following into /etc/fail2ban/jail.local
  ${normal}"
  echo "# Default banning action (e.g. iptables, iptables-new,
# iptables-multiport, shorewall, etc) It is used to define
# action_* variables. Can be overridden globally or per
# section within jail.local file

[ssh]

enabled  = true
banaction = iptables-multiport
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 5
findtime = 43200
bantime = 86400" | sudo tee /etc/fail2ban/jail.local
  # Restarting fail2ban
  echo "${green}
  Restarting fail2ban
  ${normal}"
  sudo systemctl restart fail2ban
  # Tell the user what the protections are set to
  echo "${green}
  fail2ban is now protecting SSH with the following defaults:
  maxretry: 5
  findtime: 12 hours (43200 seconds)
  bantime: 24 hours (86400 seconds)
  ${normal}"

#Explain what was done
echo "${green}
Description of what was done:
1. Ensured a non-root user is set up.
2. Ensured non-root user also has sudo permission (script won't continue without it).
3. Ensured SSH is allowed and ufw firewall is enabled.
4. Locked down SSH so it only allows key-based authentication if you chose "y" for that step.
5. Installed fail2ban and configured it to protect SSH.
[note] For a default Ubuntu server installation, automatic security updates are enabled so no action was taken regarding updates.
${normal}"

#################################################
#          CentOS / Red Hat Section             #
#################################################

elif [ "$osName" == "CentOS Linux" ] || [ "$osName" == "Red Hat Enterprise Linux" ]
then

  echo "${green}  You're running "$osName". "$osName" security first 
  measures will be applied.

  You will be prompted for your sudo password.
  Please enter it when asked.
  ${normal}
  "

fi
