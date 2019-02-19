#!/bin/bash

#############################################################################################################################################################################
# IF PLANNING TO RUN ZELNODE FROM HOME/OFFICE/PERSONAL EQUIPMENT & NETWORK!!!
# You must understand the implications of running a ZelNode on your on equipment and network. There are many possible security issues. DYOR!!!
# Running a ZelNode from home should only be done by those with experience/knowledge of how to set up the proper security.
# It is recommended for most operators to use a VPS to run a ZelNode
#
#**Potential Issues (not an exhaustive list):**
#1. Your home network IP address will be displayed to the world. Without proper network security in place, a malicious person sniff around your IP for vulnerabilities to access your network.
#2. Port forwarding: The p2p port for ZelCash will need to be open.
#3. DDOS: VPS providers typically provide mitigation tools to resist a DDOS attack, while home networks typically don't have these tools.
#4. Zelcash daemon is ran with sudo permissions, meaning the daemon has elevated access to your system. **Do not run a ZelNode on equipment that also has a funded wallet loaded.**
#5. Static vs. Dynamic IPs: If you have a revolving IP, every time the IP address changes, the ZelNode will fail and need to be stood back up.
#6. Anti-cheating mechanisms: If a ZelNode fails benchmarking/anti-cheating tests too many times in the future, its possible your IP will be blacklisted and no nodes can not dirun using that public-facing IP.
#7. Home connections typically have a monthly data cap. ZelNodes will use 2.5 - 6 TB monthly usage depending on ZelNode tier, which can result in overage charges. Check your ISP agreement.
#8. Many home connections provide adequate download speeds but very low upload speeds. ZelNodes require 100mbps (12.5MB/s) download **AND** upload speeds. Ensure your ISP plan can provide this continually. 
#9. ZelNodes can saturate your network at times. If you are sharing the connection with other devices at home, its possible to fail a benchmark if network is saturated.
#############################################################################################################################################################################


###### you must be loged in a sudo user not root!!!!#######


COIN_NAME='zelcash'

#wallet information
WALLET_DOWNLOAD='https://github.com/zelcash/zelcash/releases/download/v3.0.0/ZelCash-Linux.tar.gz'
WALLET_BOOTSTRAP='https://zelcore.io/zelcashbootstraptxindex.zip'
BOOTSTRAP_ZIP_FILE='zelcashbootstraptxindex.zip'
WALLET_TAR_FILE='ZelCash-Linux.tar.gz'
ZIPTAR='unzip'
CONFIG_FILE='zelcash.conf'
RPCPORT=16124
PORT=16125
COIN_DAEMON='zelcashd'
COIN_CLI='zelcash-cli'
RPCUSER=`pwgen -1 8 -n`
COIN_PATH='/usr/bin'
USERNAME=$(who -m | awk '{print $1;}')
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'
STOP='\e[0m'
FETCHPARAMS='https://raw.githubusercontent.com/zelcash/zelcash/master/zcutil/fetch-params.sh'
#end of required details
#
#
#

clear
echo -e '\033[1;33m=======================================================\033[0m'
echo -e 'ZelNode Setup, v2.0'
echo -e '\033[1;33m=======================================================\033[0m'
echo -e '\033[1;34m19 Feb. 2019, by alltank fam, dk808zelnode, Goose-Tech & Skyslayer\033[0m'
echo -e
echo -e '\033[1;36mNode setup starting, press [CTRL-C] to cancel.\033[0m'
sleep 3

echo -e
#Suppressing password promts for this user so zelnode can operate
sudo echo -e "$(who -m | awk '{print $1;}') ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo

echo -e "\033[1;33m=======================================================\033[0m"
echo "INSTALLING ZELNODE DEPENDENCIES"
echo -e "\033[1;33m=======================================================\033[0m"
echo "Installing packages and updates..."
sudo apt-get update -y
sudo apt-get install software-properties-common -y
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install nano htop pwgen ufw -y
sudo apt-get install build-essential libtool pkg-config -y
sudo apt-get install libc6-dev m4 g++-multilib -y
sudo apt-get install autoconf ncurses-dev unzip git python python-zmq -y
sudo apt-get install wget curl bsdmainutils automake -y
echo -e "\033[1;33mPackages complete...\033[0m"
echo -e
function jumpto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

start=${1:-"start"}

jumpto $start

start:
WANIP=$(wget http://ipecho.net/plain -O - -q)

echo -e 'Detected IP Address is' $WANIP
echo -e
read -p 'Is IP Address correct? [Y/n] ' -n 1 -r
if [[ $REPLY =~ ^[Nn]$ ]]
then
    echo -e
    read -p 'Enter the IP address for your VPS, then hit [ENTER]: ' WANIP
fi
PASSWORD=`pwgen -1 20 -n`
if [ "x$PASSWORD" = "x" ]; then
    PASSWORD=${WANIP}-`date +%s`
fi
    echo -e "\n\033[1;34mCreating MainNet Conf File...\033[0m"
    sleep 3
    mkdir ~/.zelcash
    cp ~/.zelcash/zelcash.conf ~/.zelcash/zelcash.org
	rm ~/.zelcash/zelcash.conf
    touch ~/.zelcash/$CONFIG_FILE
	    echo "rpcuser=$RPCUSER" >> ~/.zelcash/$CONFIG_FILE
    echo "rpcpassword=$PASSWORD" >> ~/.zelcash/$CONFIG_FILE
    echo "rpcallowip=127.0.0.1" >> ~/.zelcash/$CONFIG_FILE
    echo "rpcport=$RPCPORT" >> ~/.zelcash/$CONFIG_FILE
    echo "port=$PORT" >> ~/.zelcash/$CONFIG_FILE
    echo "zelnode=1" >> ~/.zelcash/$CONFIG_FILE
    echo -e "\033[1;33mEnter your MAINNET ZELNODE PRIVATE KEY generated by your Swing/Zelcore wallet: \033[0m"
    read zelnodeprivkey && echo zelnodeprivkey=$zelnodeprivkey >> ~/.zelcash/$CONFIG_FILE
    echo "server=1" >> ~/.zelcash/$CONFIG_FILE
    echo "daemon=1" >> ~/.zelcash/$CONFIG_FILE
    echo "txindex=1" >> ~/.zelcash/$CONFIG_FILE
    echo "listen=1" >> ~/.zelcash/$CONFIG_FILE
    echo "logtimestamps=1" >> ~/.zelcash/$CONFIG_FILE
    echo "externalip=$WANIP" >> ~/.zelcash/$CONFIG_FILE
    echo "bind=$WANIP" >> ~/.zelcash/$CONFIG_FILE
    echo "addnode=explorer.zel.cash" >> ~/.zelcash/$CONFIG_FILE
    echo "maxconnections=999" >> ~/.zelcash/$CONFIG_FILE

sleep 3

#begin downloading wallet binaries
echo -e "\033[1;32mKilling and removing all old instances of $COIN_NAME and Downloading new wallet...\033[0m"
sudo killall $COIN_DAEMON > /dev/null 2>&1
cd /usr/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && sleep 2
# added to be sure to delete the old files for someone using the old script
cd /usr/local/bin && sudo rm $COIN_CLI $COIN_DAEMON > /dev/null 2>&1 && sleep 2
cd
wget -c $WALLET_DOWNLOAD -O - | sudo tar -xz
sudo cp zelcashd /usr/bin
sudo cp zelcash-cli /usr/bin
sudo chmod u+x /usr/bin/zelcash*
sudo rm -rf $WALLET_TAR_FILE
cd
    echo -e "\033[1;32mDownloading wallet bootstrap file...\033[0m"
    echo -e
    mkdir ~/zeltemp

    wget -c $WALLET_BOOTSTRAP -O ~/zeltemp/$BOOTSTRAP_ZIP_FILE
    echo -e "\033[1;32mExtracting bootstrap files, this will take some time...\033[0m"
    sleep 3
    unzip -n ~/zeltemp/$BOOTSTRAP_ZIP_FILE -d ~/zeltemp
	unzip -n ~/zeltemp/$BOOTSTRAP_ZIP_FILE -d ~/zeltemp
	cp -r ~/zeltemp/chainstate ~/.zelcash/
	cp -r ~/zeltemp/blocks ~/.zelcash/  
	rm ~/zeltemp -R
    echo -e
    echo -e "\033[1;33mDone downloading wallet bootstrap file.\033[0m"
#end download/extract bootstrap file

cd
echo -e "\033[1;32mDownloading chain params...\033[0m"
wget $FETCHPARAMS
chmod u+x fetch-params.sh
bash fetch-params.sh
echo -e "\033[1;33mDone fetching chain params\033[0m"

echo -e "\033[1;32mCreating system service file....\033[0m"
sudo touch /etc/systemd/system/$COIN_NAME.service
sudo chown $USERNAME:$USERNAME /etc/systemd/system/$COIN_NAME.service
cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
Type=forking
User=$USERNAME
Group=$USERNAME
WorkingDirectory=/home/$USERNAME/.zelcash/
ExecStart=$COIN_PATH/$COIN_DAEMON -datadir=/home/$USERNAME/.zelcash/ -conf=/home/$USERNAME/.zelcash/$CONFIG_FILE -daemon
ExecStop=-$COIN_PATH/$COIN_CLI stop
Restart=always
RestartSec=3
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
sudo chown root:root /etc/systemd/system/$COIN_NAME.service
sudo systemctl daemon-reload
sleep 3
sudo systemctl enable $COIN_NAME.service &> /dev/null

echo -e "\033[1;33mSystemctl Complete....\033[0m"

echo "If you see *error* message, do not worry we are killing wallet again to make sure its dead"
echo ""
echo -e "\033[1;33m=================================================================="
echo "DO NOT CLOSE THIS WINDOW OR TRY TO FINISH THIS PROCESS "
echo "PLEASE WAIT 2 MINUTES UNTIL YOU SEE THE RELOADING WALLET MESSAGE"
echo -e "==================================================================\033[0m"
echo ""

echo -e "\033[1;32mConfiguring firewall and enabling fail2ban...\033[0m"
sudo ufw allow ssh/tcp
sudo ufw allow $PORT/tcp
sudo ufw logging on
sudo ufw default deny incoming
sudo ufw default allow outgoing
echo "y" | sudo ufw enable >/dev/null 2>&1
sudo systemctl enable fail2ban >/dev/null 2>&1
sudo systemctl start fail2ban >/dev/null 2>&1
echo -e "\033[1;33mBasic security completed...\033[0m"

echo -e "\033[1;32mRestarting $COIN_NAME wallet with new configs, 30 seconds...\033[0m"
$COIN_DAEMON -daemon
for (( counter=30; counter>0; counter-- ))
do
echo -n ". "
sleep 1
done
printf "\n"

echo -e "\033[1;32mGetting info...\033[0m"
$COIN_CLI getinfo

echo -e "\033[1;32mStarting your zelnode with final details\033[0m"

sleep 10

printf "\033[1;34m"
figlet -t -k "WELCOME   TO   zelnodes" 
printf "\e[0m"

echo "============================================================================="
echo -e "\033[1;32mPLEASE COMPLETE THE ZELNODE SETUP IN YOUR ZELCORE WALLET\033[0m"
echo -e "COURTESY OF \033[1;32mALTTANK FAM\033[0m, \033[1;32mDK808 \033[0mAND \033[1;32mGOOSE-TECH \033[0m"
echo "============================================================================="
echo -e
sleep 15
for (( countera=15; countera>0; countera-- ))
do
clear
sudo zelcash-cli getinfo
echo -e '\033[1;32mPress CTRL-C when correct blockheight has been reached.\033[0m'
    for (( counterb=30; counterb>0; counterb-- ))
    do
    echo -n ". "
    sleep 1
    done
done
printf "\n"
