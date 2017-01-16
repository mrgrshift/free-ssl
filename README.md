# free-ssl
This script will help you to generate a trusted SSL certificate issued by Letsencrypt (letsencrypt.org).<br>
This script uses https://github.com/certbot/certbot

## Requisites
* Obligatory, you need to have your own domain. Follow [this guide] (https://forum.lisk.io/viewtopic.php?f=38&t=1367) if you want a free domain.
	* If the domain for your server is http://server01.yourdomain.com/ use --> `server01.yourdomain.com`
* You need to be familiar with ufw, follow this guide: [UFW - First time with a firewall] (https://forum.lisk.io/viewtopic.php?f=38&t=1342)
* You need to know your [Network Interface] (http://www.computerhope.com/unix/uifconfi.htm).<br>

## Install trusted SSL certificate issued by Letsencrypt
If you have a domain install a trusted SSL certificate issued by Letsencrypt use: `bash installssl.sh`<br>
**installssl.sh** will guide you through the installation process.<br>
To see the result of the script go to: *~/free-ssl/logs/installssl.log*
#### Renew letsencrypt certificate
You need to complete all the installssl.sh instructions, at the end it will tell you to add one line to your cron jobs. This line will do the job of checking the expiring date of your certificate.<br>
`renewssl.sh` will renew your certificate if the expiration date is less than 30 days.<br>
To see the result of the script go to: *~/free-ssl/logs/renewssl.log*<br>
**IMPORTANT NOTICE** renewssl.sh also will perform *bash lisk.sh reload*, please check before enable automatic renewal if your managment script can handle a random reload of Lisk.<br>

## Install self signed certificate.
If you don't have your own domain you can still generate a SSL certificate, use `bash localssl.sh`<br>
It is recommended to have a domain and update your certificate with *installssl.sh*<br>
This type of certificate doesn't need the renewssh.sh script.<br>
To see the result of the script go to: *~/free-ssl/logs/localssl.log*<br>

## Vote/Donate
If you like this script please consider to vote/donate to this accounts:<br>
LISK: [3125853987625788223L] (https://explorer.lisk.io/address/3125853987625788223L)<br>
SHIFT: [14156057994616021440S] (https://explorer.shiftnrg.org/address/14156057994616021440S)<br>

## Links
Documentation: https://certbot.eff.org/docs <br>
Software project: https://github.com/certbot/certbot <br>
Notes for developers: https://certbot.eff.org/docs/contributing.html <br>
Main Website: https://certbot.eff.org <br>
Let's Encrypt Website: https://letsencrypt.org <br>
Community: https://community.letsencrypt.org <br>
ACME spec: http://ietf-wg-acme.github.io/acme/ <br>
ACME working area in github: https://github.com/ietf-wg-acme/acme <br>
