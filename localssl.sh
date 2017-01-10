#!/bin/bash
#This script will help you to generate a local ssl for your server
#With this you can enable ssl in your config.json
#Before you do a bash lisk.sh reload first check if your delegate is about to forge



#created by mrgr. Please consider to vote for mrgr delegate


CYAN='\033[1;36m'
OFF='\033[0m'
echo
echo "----------------------------------------"
echo "Welcome to localssl script"
echo -e "Don't forget to vote for ${CYAN}mrgr${OFF} delegate"
echo "----------------------------------------"
echo

LOG=logs/localssl.log
COUNTRY=DE
STA=Berlin
LOC=Germany
ORG=LISK
ORU=LSK
PASS=$(date +%s | sha256sum | base64 | head -c 32 ; echo)

if [ -f "$1" ]; then
	case $1 in
	"main")
		echo "You are installing this script for mainnet"
		VERSION="lisk-main"
	;;
	"test")
		echo "You are installing this script for testnet"
		VERSION="lisk-test"
	;;
	*)
                echo "You are installing this script for mainnet"
                VERSION="lisk-main"
        ;;
	esac
else
	echo "You are installing this script for mainnet"
	echo "If you want to change this script to testnet please stop this installation and start again with:"
	echo "bash install.sh test"
	VERSION="lisk-main"
fi

mkdir -p ../$VERSION/ssl/

echo "Please enter the following information:"
echo -n "Name of your delegate: "
	read DELEGATE_NAME
echo -n "Type an email: "
	read EMAIL
echo -n "Enter the port you will use for HTTPS: "
        read HTTPS_PORT

TIME=$(date +"%H:%M") #for your local time add:  -d '6 hours ago')

echo "$TIME Starting to generate ssl" > $LOG

	openssl genrsa -des3 -passout pass:"$PASS" -out "$DELEGATE_NAME".key 2048 >> $LOG 2>&1
	if [ $? != 0 ]; then
		echo "X Failed to create ssl key"
		echo "Exiting.."
		exit 0
	else
		echo "ssl key created" >> $LOG
	fi

	#Remove password from key
	openssl rsa -in "$DELEGATE_NAME".key -passin pass:"$PASS" -out "$DELEGATE_NAME".key >> $LOG 2>&1
        if [ $? != 0 ]; then
                echo "X Failed to clean ssl key"
                echo "Exiting.."
                exit 0
        fi

	openssl req -new -key "$DELEGATE_NAME".key -out "$DELEGATE_NAME".csr -passin pass:"$PASS" -subj "/C=$COUNTRY/ST=$STA/L=$LOC/O=$ORG/OU=$ORU/CN=$DELEGATE_NAME/emailAddress=$EMAIL" >> $LOG 2>&1
        if [ $? != 0 ]; then
                echo "X Failed to create csr"
                echo "Exiting.."
                exit 0
	else
		echo "csr created" >> $LOG
        fi

	openssl x509 -req -days 365 -in "$DELEGATE_NAME".csr -signkey "$DELEGATE_NAME".key -out "$DELEGATE_NAME".crt >> $LOG 2>&1
        if [ $? != 0 ]; then
                echo "X Failed to create SSL certificate"
                echo "Exiting.."
                exit 0
        else
                echo "SSL certificate created" >> $LOG
        fi

	if [[ -f "$DELEGATE_NAME".crt ]] && [[ -f "$DELEGATE_NAME".key ]]; then
        	cat "$DELEGATE_NAME".crt "$DELEGATE_NAME".key > "$DELEGATE_NAME".pem
	fi

	#FINISHING AND CLEANING
	mv "$DELEGATE_NAME".pem ../$VERSION/ssl/
	rm $DELEGATE_NAME*

echo
echo "Your SSL Certificate has been created successfully."
echo "Go to your lisk config.json file and edit ssl section like the following:"
echo "    \"ssl\": {"
echo -e "        \"enabled\": ${CYAN}true${OFF},"
echo "        \"options\": {"
echo -e "            \"port\": ${CYAN}$HTTPS_PORT${OFF},"
echo "            \"address\"\: \"0.0.0.0\","
echo -e "            \"key\": \"${CYAN}./ssl/$DELEGATE_NAME.pem${OFF}\","
echo -e "            \"cert\": \"${CYAN}./ssl/$DELEGATE_NAME.pem${OFF}\""
echo "        }"
echo "    },"

echo
echo "After edit config.json reload lisk: bash lisk.sh reload."
echo "Now you will be able to access to your wallet in a more secure way."
echo "Try the following (change the example IP for yours):"
echo "http://123.123.123.123:$HTTPS_PORT/"
