#!/bin/bash
#This script will help you to generate a trusted SSL certificate issued by letsencrypt
#This script use https://github.com/certbot/


#Don't forget to vote for mrgr delegate in Lisk: 3125853987625788223L
#Don't forget to vote for mrgr delegate in Shift: 14156057994616021440S

SSLUSER=$USER
LOCAL_HOME=$(pwd)
CONF=$(pwd)/config.sh
LOG=$(pwd)/logs/installssl.log
CYAN='\033[1;36m'
OFF='\033[0m'
mkdir -p logs
echo "++++++++++++++++++++" >> $LOG
echo "Installation start.." >> $LOG
echo

if [ -f "config.sh" ]; then
	echo "**A previous installation was detected.."
	echo "This script is meant to be executed only once."
	echo "If you are trying to run it again is because you possibly had a problem, if so please contact mrgr in https://lisk.chat/direct/mrgr or in https://shiftnrg.slack.com/messages/@mrgr/"
	exit 0
fi

echo "This script will help you to get a new certificate from letsencrypt. Please follow the instructions."
echo
echo -n "Enter your domain name: "
	read DOMAIN_NAME
echo -n "Enter your email: "
        read EMAIL
echo -n "Enter the port you will use for HTTPS: "
        read HTTPS_PORT
echo
echo "Now this script need something from you."
echo -e "Before proceeding please check your ufw configuration, execute in a new terminal: ${CYAN}sudo ufw status${OFF}"
echo "You need to have your own ports enable, obligatory your SSH port and your LISK/SHIFT client port."
echo "Execute ifconfig in the other terminal and look for network interface (normally is eth0, eth1, eth2, ens1, ens2, ens3...)."
echo -n "What is your network interface?: "
        read NETWORK_INTERFACE
echo
echo "Your domain name is: $DOMAIN_NAME" >> $LOG
echo "Your email is: $EMAIL" >> $LOG
echo "Your https port is: $HTTPS_PORT" >> $LOG
echo "Your network interface is: $NETWORK_INTERFACE" >> $LOG

echo
echo -n "Enabling port 443/tcp.. "
echo "Enabling port 443/tcp.." >> $LOG
sudo ufw allow 443/tcp &>> $LOG || { echo "Could not enable port 443. Please read your logs/installssl.log file. Exiting." && exit 1; }
sudo cp /etc/ufw/before.rules before.rules.backup #Backing up file /etc/ufw/before.rules
echo "done"
echo "done" >> $LOG

echo
echo -n "Installing certbot.. "
echo "Installing certbot.." >> $LOG
cd /opt
sudo git clone https://github.com/certbot/certbot.git &>> $LOG || { echo "Could not clone git certbot source. Please read your logs/installssl.log file. Exiting." && exit 1; }
echo "done"
echo "done" >> $LOG
export LC_ALL="en_US.UTF-8" >> $LOG
export LC_CTYPE="en_US.UTF-8" >> $LOG

echo
echo -n "Generating new SSL certificate.. this could take some minutes.."
echo "Generating new SSL certificate.." >> $LOG
/opt/certbot/certbot-auto certonly --standalone -d $DOMAIN_NAME --email $EMAIL --agree-tos --non-interactive &>> $LOG || { echo "Could not generate SSL certificate. Please read your logs/installssl.log file. Exiting." && exit 1; }
echo "done"
echo "done" >> $LOG
sudo chmod 755 /etc/letsencrypt/archive/
sudo chmod 755 /etc/letsencrypt/live/

echo
echo -n "Installing redirection on port 443 to port $HTTPS_PORT.. "
echo "Installing redirection on port 443 to port $HTTPS_PORT.. " >> $LOG
sudo sh -c "echo >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"# MRGR -- Auto-Redirect \" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"*nat\" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \":PREROUTING ACCEPT [0:0]\" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"-A PREROUTING -i $NETWORK_INTERFACE -p tcp --dport 443 -j REDIRECT --to-port $HTTPS_PORT\" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"COMMIT\" >> /etc/ufw/before.rules" >> $LOG
echo "done"
echo "done" >> $LOG

cd $LOCAL_HOME
echo "SSLUSER=\"$SSLUSER\"" > $CONF
echo "DOMAIN=\"$DOMAIN_NAME\"" >> $CONF
echo "EMAIL=\"$EMAIL\"" >> $CONF
echo "HTTPS_PORT=\"$HTTPS_PORT\"" >> $CONF
echo "NETWORK_INTERFACE=\"$NETWORK_INTERFACE\"" >> $CONF

echo
echo "*************************************** Please do the following:"
echo "Run: sudo nano /etc/ufw/before.rules"
echo "And go to the bottom of the file and check your las 4 lines, should be like follow:"
echo "    *nat"
echo "    :PREROUTING ACCEPT [0:0]"
echo "    -A PREROUTING -i $NETWORK_INTERFACE -p tcp --dport 443 -j REDIRECT --to-port $HTTPS_PORT"
echo "    COMMIT"
echo
echo "Please confirm the above. If everything is right this script needs to reload your firewall."
echo "* Be aware that if the /etc/ufw/before.rules file contains other type of lines at the end of the file your firewall might not work properly."
echo "* If you are seeing other type of lines don't worry, this script has backed up your file and you can find it here: $LOCAL_HOME/before.rules.backup"
echo "* If you don't accept the following question this script will restore your file to the above version."

	read -p "Do you want to continue (y/n)?: " -n 1 -r
	if [[  $REPLY =~ ^[Yy]$ ]]
	   then
		echo "Deleting allow 443/tcp rule.." >> $LOG
		sudo ufw delete allow 443/tcp &>> $LOG || { echo "Could not remove allow 443/tcp rule. Please read your logs/installssl.log file. Exiting." && exit 1; }
		echo "Allowing your https port $HTTPS_PORT/tcp.." >> $LOG
		sudo ufw allow $HTTPS_PORT/tcp &>> $LOG || { echo "Could not allow $HTTPS_PORT/tcp rule. Please read your logs/installssl.log file. Exiting." && exit 1; }
		echo "ufw reload.." >> $LOG
		sudo ufw reload &>> $LOG || { echo "Could not reload ufw. Please read your logs/installssl.log file. Exiting." && exit 1; }
	else
		echo
		echo "You have decided not to continue. Please add the lines described above for /etc/ufw/before.rules and reload your firewall manually."
		exit 0
	fi

echo
echo "Your SSL Certificate has been created successfully, now you need to perform the following manual task."
echo "Your SSL Certificate has been created successfully" >> $LOG
echo
echo "Go to your lisk config.json file and edit ssl section like the following:"
echo "    \"ssl\": {"
echo -e "        \"enabled\": ${CYAN}true${OFF},"
echo "        \"options\": {"
echo -e "            \"port\": ${CYAN}$HTTPS_PORT${OFF},"
echo "            \"address\"\: \"0.0.0.0\","
echo -e "            \"key\": \"${CYAN}/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem${OFF}\","
echo -e "            \"cert\": \"${CYAN}/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem${OFF}\""
echo "        }"
echo "    },"
echo "Edit your config.json in \"ssl\", write your port $HTTPS_PORT and change the following lines:" >> $LOG
echo "\"key\": \"/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem\"" >> $LOG
echo "\"cert\": \"/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" >> $LOG

echo
echo "Save and exit from your confir.json file."
echo "For Lisk perform : bash lisk.sh reload"
echo "For Shift perform: ./shift_manager.bash stop && ./shift_manager.bash start"
echo "                   or simply stop and start your node app.js"
echo
echo -e "${CYAN}Installation Successfully Completed${OFF}"
echo "Installation Successfully Completed" >> $LOG
echo
echo "Now you can visit your address https://$DOMAIN_NAME and see the result. :)."
echo
echo "Don't forget to vote for mrgr delegate."
echo "Now you can visit your address https://$DOMAIN_NAME and see the result. :)." >> $LOG
echo "Don't forget to vote for mrgr delegate." >> $LOG

