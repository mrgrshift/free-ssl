#!/bin/bash
# This script will help you to generate a trusted SSL certificate issued by Let's Encrypt
# This script uses https://github.com/certbot/certbot


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
	echo "**A previous installation was detected.." | tee -a $LOG
	echo "This script is meant to be executed only once." | tee -a $LOG
	echo "If you are trying to run it again is because you possibly had a problem, if so please contact mrgr in https://lisk.chat/direct/mrgr or in https://shiftnrg.slack.com/messages/@mrgr/" | tee -a $LOG
	exit 0
fi

echo "This script will help you to get a trusted SSL certificate issued by Let's Encrypt. Please follow the instructions."
echo
echo -n "Enter your domain name: "
	read DOMAIN_NAME
echo -n "Enter your email: "
        read EMAIL
echo -n "Enter the port you will use for HTTPS: "
        read HTTPS_PORT
echo
echo "To continue the process, make sure to follow the instructions given below. Note, that the commands should be executed in another terminal."
echo -e "Check your ufw configuration: Execute in a new terminal: ${CYAN}sudo ufw status${OFF}"
echo "You'll need to have following ports enabled: Your SSH port and your SHIFT client port."
echo -e "Execute ${CYAN}ifconfig${OFF} in the other terminal and look for your network interface (normally is eth0, eth1, eth2, ens1, ens2, ens3...)."
echo -n "What is your network interface?: "
        read NETWORK_INTERFACE
echo
echo "Please check your data: "
echo "Your domain name is: $DOMAIN_NAME" >> $LOG
echo "Your email is: $EMAIL" >> $LOG
echo "Your https port is: $HTTPS_PORT" >> $LOG
echo "Your network interface is: $NETWORK_INTERFACE" >> $LOG

echo
echo -n "Enabling port 443/tcp.. " | tee -a $LOG
sudo ufw allow 443/tcp &>> $LOG || { echo "Could not enable port 443. Please read your logs/installssl.log file. Exiting."  | tee -a $LOG && exit 1; }
sudo cp /etc/ufw/before.rules before.rules.backup # Backing up firewall /etc/ufw/before.rules
echo "Done." | tee -a $LOG

echo
echo -n "Installing certbot.. " | tee -a $LOG
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install certbot
echo "Done." | tee -a $LOG
export LC_ALL="en_US.UTF-8" >> $LOG
export LC_CTYPE="en_US.UTF-8" >> $LOG

echo
echo -n "Generating new SSL certificate. This can take a few minutes..." | tee -a $LOG
certbot certonly --standalone -d $DOMAIN_NAME --email $EMAIL --agree-tos --non-interactive &>> $LOG || { echo "Could not generate SSL certificate. Please read your logs/installssl.log file. Exiting." | tee -a $LOG && exit 1; }
echo "Done" | tee -a $LOG
sudo chmod 755 /etc/letsencrypt/archive/
sudo chmod 755 /etc/letsencrypt/live/

echo
echo -n "Installing redirection on port 443 to port $HTTPS_PORT.. " | tee -a $LOG
sudo sh -c "echo >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"# HTTPS -- Auto-Redirect \" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"*nat\" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \":PREROUTING ACCEPT [0:0]\" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"-A PREROUTING -i $NETWORK_INTERFACE -p tcp --dport 443 -j REDIRECT --to-port $HTTPS_PORT\" >> /etc/ufw/before.rules" >> $LOG
sudo sh -c "echo \"COMMIT\" >> /etc/ufw/before.rules" >> $LOG
echo "done" | tee -a $LOG

cd $LOCAL_HOME
echo "SSLUSER=\"$SSLUSER\"" > $CONF
echo "DOMAIN=\"$DOMAIN_NAME\"" >> $CONF
echo "EMAIL=\"$EMAIL\"" >> $CONF
echo "HTTPS_PORT=\"$HTTPS_PORT\"" >> $CONF
echo "NETWORK_INTERFACE=\"$NETWORK_INTERFACE\"" >> $CONF

echo
echo "To prevent damage to your firewall, please do the following:"
echo -e "Run: ${CYAN}sudo nano /etc/ufw/before.rules${OFF}"
echo "Go to the bottom of the file and check the last 4 lines, that should look like this:"
echo "    *nat"
echo "    :PREROUTING ACCEPT [0:0]"
echo "    -A PREROUTING -i $NETWORK_INTERFACE -p tcp --dport 443 -j REDIRECT --to-port $HTTPS_PORT"
echo "    COMMIT"
echo
echo "If everything is OK, confirm the following dialog with y. If not, please confirm the dialog with n. This will recover your firewall."
echo "* Be aware: If the /etc/ufw/before.rules file contains other type of lines at the end of the file your firewall might not work properly."
echo 

	read -p "Do you want to continue (y/n)?: " -n 1 -r
	if [[  $REPLY =~ ^[Yy]$ ]]
	   then
		echo "Deleting allow 443/tcp rule.." >> $LOG
		sudo ufw delete allow 443/tcp &>> $LOG || { echo "Could not remove allow 443/tcp rule. Please read your logs/installssl.log file. Exiting." | tee -a $LOG && exit 1; }
		echo "Allowing your https port $HTTPS_PORT/tcp.." >> $LOG
		sudo ufw allow $HTTPS_PORT/tcp &>> $LOG || { echo "Could not allow $HTTPS_PORT/tcp rule. Please read your logs/installssl.log file. Exiting." | tee -a $LOG && exit 1; }
		echo "ufw reload.." >> $LOG
		sudo ufw reload &>> $LOG || { echo "Could not reload ufw. Please read your logs/installssl.log file. Exiting." | tee -a $LOG && exit 1; }
	else
		echo -n "Restoring ufw/before.rules.." | tee -a $LOG
		sudo rm /etc/ufw/before.rules >> $LOG
		sudo cp before.rules.backup /etc/ufw/before.rules >> $LOG
		echo "done" | tee -a $LOG
		echo
		echo "You have decided not to continue. Please add the lines described above for /etc/ufw/before.rules and reload your firewall manually." | tee -a $LOG
		exit 0
	fi

echo
echo
echo "--> Your SSL Certificate has been created successfully, now you'll need to perform the following manual task." | tee -a $LOG
echo
echo "Go to your Shift config.json file and edit SSL section like this:" | tee -a $LOG
echo "    \"ssl\": {" | tee -a $LOG
echo -e "        \"enabled\": ${CYAN}true${OFF},"
echo "        \"enabled\": true," >> $LOG
echo "        \"options\": {" | tee -a $LOG
echo -e "            \"port\": ${CYAN}$HTTPS_PORT${OFF},"
echo "            \"port\": $HTTPS_PORT," >> $LOG
echo "            \"address\"\: \"0.0.0.0\"," | tee -a $LOG
echo -e "            \"key\": \"${CYAN}/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem${OFF}\","
echo "            \"key\": \"/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem\"," >> $LOG
echo -e "            \"cert\": \"${CYAN}/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem${OFF}\""
echo "            \"cert\": \"/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem\"" >> $LOG
echo "        }" | tee -a $LOG
echo "    }," | tee -a $LOG

echo
echo "Save and exit from your config.json file." | tee -a $LOG
#echo "For Shift users perform following command in the shift directory: ./shift_manager.bash reload" | tee -a $LOG
echo
echo -e "${CYAN}Installation Successfully Completed${OFF}"
echo "Installation Successfully Completed" >> $LOG
echo
echo "Now you can visit your address https://$DOMAIN_NAME and see the result. :)" | tee -a $LOG
echo " "  | tee -a $LOG
echo "The Certbot packages on your system come with a cron job that will renew your certificates automatically before they expire." 
echo "Since Let's Encrypt certificates last for 90 days, it's highly advisable to take advantage of this feature." 
echo "You can test automatic renewal for your certificates by running this command:"
echo "certbot renew --dry-run"
certbot renew --dry-run
echo "More detailed information and options about renewal can be found in the full documentation."