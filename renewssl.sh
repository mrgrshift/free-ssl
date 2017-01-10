#!/bin/bash

if ! [ -f "config.sh" ]; then
        echo "Please run the installer first"
        exit 0
fi

source config.sh
LOG=/home/$SSLUSER/free-ssl/logs/renewssl.log
RENEW="0"
TIME=$(date "+DATE: %Y-%m-%d%nTIME: %H:%M:%S")
cert="/etc/letsencrypt/live/$DOMAIN/cert.pem"
echo "############ Checking expiring date on cert $cert" >> $LOG
if openssl x509 -checkend 86400 -noout -in $cert
then
  echo "The certificate is good." >> $LOG
  today=`date +%D`
  expiredate=`openssl x509 -enddate -noout -in $cert  | awk -F'=' '{print $2}'`
  expdate="date +%D --date='$expiredate'"
  ed=`eval $expdate`
  daysleft=`echo $(($(($(date -u -d "$ed" "+%s") - $(date -u -d "$today" "+%s"))) / 86400))`
  echo "Today's date: $today" >> $LOG
  echo "Expiring on : $ed" >> $LOG
  echo "Days left : $daysleft" >> $LOG
  echo " " >> $LOG
  if [ "$daysleft" -lt "30" ]; then
        echo "Less than 30 days.. it will start the renewal script.." >> $LOG
        RENEW="1"
  else
        echo "Greater than 30 days, no need to renew." >> $LOG
  fi
else
  echo "This certificate does not exist or could not be successfully renewed. You can do the following:" >> $LOG
  echo " - Check if your domain is still alive." >> $LOG
  echo " - Check if the folder /etc/letsencrypt/live/$DOMAIN/ exists and it contain *.pem files." >> $LOG
  echo " - If nothing of the above works, remove /etc/letsencrypt/live/$DOMAIN/ and run the installer again: bash installssl.sh" >> $LOG
fi
echo "############" >> $LOG
echo " " >> $LOG

if [ "$RENEW" -eq "1" ]; then
echo "+++++++++++++++++++++++" >> $LOG
echo "Starting renew script" >> $LOG
echo "$TIME" >> $LOG
echo "Removing port redirect.." >> $LOG
sudo head -n -4 /etc/ufw/before.rules > before.rules
sudo rm /etc/ufw/before.rules >> $LOG
sudo cp before.rules /etc/ufw/before.rules >> $LOG
echo "done" >> $LOG
echo "Running certbot-auto renew.." >> $LOG
sudo ufw allow 443/tcp &> /dev/null
sudo /opt/certbot/certbot-auto renew --agree-tos >> $LOG || { echo "Could not generate SSL certificate in renewssl.sh. Please read your logs/renewssl.log file. Exiting." | tee -a $LOG && exit 1; }
sudo ufw delete allow 443/tcp &> /dev/null
sudo ufw reload >> $LOG
echo "done" >> $LOG
echo -n "Installing port redirect.." >> $LOG
echo "*nat" >> before.rules
echo ":PREROUTING ACCEPT [0:0]" >> before.rules
echo "-A PREROUTING -i $NETWORK_INTERFACE -p tcp --dport 443 -j REDIRECT --to-port $HTTPS_PORT" >> before.rules
echo "COMMIT" >> before.rules
sudo chmod 0644 before.rules >> $LOG
sudo chown root:root before.rules >> $LOG
sudo rm /etc/ufw/before.rules >> $LOG
sudo mv before.rules /etc/ufw/before.rules >> $LOG
echo "done" >> $LOG
echo "Reload firewall.." >> $LOG
sudo ufw reload >> $LOG
echo "done" >> $LOG
if [ "$1" -eq "shift" ]; then
   echo "Stop and start Shift to take the new certificate" >> $LOG
   SHIFT_SCREEN="shift"
   screen -S $SHIFT_SCREEN -p 0 -X stuff "^C"
   screen -S $SHIFT_SCREEN -p 0 -X stuff "node app.js$(printf \\r)"
   echo "done" >> $LOG
else
   echo "Reloading Lisk to take the new certificate" >> $LOG
   bash /home/$SSLUSER/lisk-main/lisk.sh reload >> $LOG
   echo "done" >> $LOG
fi
TIME=$(date "+DATE: %Y-%m-%d%nTIME: %H:%M:%S")
echo "Certificate renewal completed" >> $LOG
echo "$TIME" >> $LOG
fi

