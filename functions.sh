function ssh-mdc() {
  # download script
  	link=https://raw.githubusercontent.com/mitapia/sh/master/mdc.sh
  	curl -o ~/tmp/mdc.sh --create-dirs "$link";
	
	scp ~/tmp/mdc.sh "$@":~;

	/usr/bin/ssh -t "$@" '
	if (( $(who | wc -l) > 1 )); then
		printf "$(tput setaf 1)There is someone currenly logged in to this server, to continue safely have all other user log off while MDC script runs.$(tput sgr0)\n";
		w;
		exit 1;
	fi
	touch ~/.bash_profile && cp ~/.bash_profile ~/.bash_profile.bak;
    echo "printf \"\$(tput setaf 1)A Manual Drive Configuration script is currently in progress, logging out.\$(tput sgr0)\n\"" >> ~/.bash_profile; 
    echo "logout;" >> ~/.bash_profile; 

    # check for a running mdc script
    screen -ls | grep mdc

	# REQUIRED PACKAGE INSTALL
	if [ -f /etc/redhat-release ]; then
		yum -y install screen curl bc;
	else
		apt-get -y install screen curl bc;
	fi

  script=mdc.sh
  chmod +x "$script";
  
  # create screen
  screen -d -m -L -S mdc;
  # run script on screen
  screen -S mdc -p 0 -X exec ./"$script";
  # attach to screen
  screen -S mdc -r;
  
  rm "$script";
  mv ~/.bash_profile.bak ~/.bash_profile;'

  rm -r ~/tmp/mdc.sh
}

function ssh-mdc-simulate() {
  	# download script
  	link=https://raw.githubusercontent.com/mitapia/sh/master/mdc_simulate.sh;
  	curl -o ~/tmp/mdc.sh --create-dirs "$link";

	scp ~/tmp/mdc.sh "$@":~;

	/usr/bin/ssh -t "$@" '
	if (( $(who | wc -l) > 1 )); then
		printf "$(tput setaf 1)There is someone currenly logged in to this server, to continue safely have all other user log off while MDC script runs.$(tput sgr0)\n";
		w;
		exit 1;
	fi
    
	# REQUIRED PACKAGE INSTALL
	if [ -f /etc/redhat-release ]; then
		yum -y install screen curl bc;
	else
		apt-get -y install screen curl bc;
	fi

  sshuser=$(whoami)
  echo "printf \"\$(tput setaf 1)$sshuser is currently running MDC sript, logging out.\$(tput sgr0)\n\"" >> ~/.progress;
  echo "Working on drive $working_drive of $total_drives" >> ~/.progress
  echo "logout;" >> ~/.progress

  script=mdc.sh
  chmod +x "$script";
  
  # create screen
  screen -d -m -L -S mdc;
  # run script on screen
  screen -S mdc -p 0 -X exec ./"$script";
  # attach to screen
  screen -S mdc -r;
  
  rm "$script";'

  rm -r ~/tmp/mdc.sh
}

function functions-update() {
	curl -O https://raw.githubusercontent.com/mitapia/sh/master/functions.sh;
	source functions.sh;
}

function ssh-verify-raid() {
	ssh "$@" "bash <(curl -s https://raw.githubusercontent.com/mitapia/sh/master/raid_verify.sh)";
}

# requested by: Fabian Jardin
function ssh-rainbow() {
  ssh -t "$@" "
    cp ~/.bashrc ~/.bashrc.bak;
    echo 'export PS1=\"\[\$(tput bold)\]\[\$(tput setaf 1)\][\[\$(tput setaf 3)\]\u\[\$(tput setaf 2)\]@\[\$(tput setaf 6)\]\h \[\$(tput setaf 5)\]\W\[\$(tput setaf 1)\]]\[\$(tput setaf 7)\]\\\\$ \[\$(tput sgr0)\]\"' >> ~/.bashrc; 
    bash -i; 
    mv ~/.bashrc.bak ~/.bashrc;"
}

function ipmi-status() {
  ipmitool -I lan -H "$1" -U ADMIN -P "$2" chassis status;
}

function ipmi-on() {
  ipmitool -I lan -H "$1" -U ADMIN -P "$2" chassis power on;
  sleep 5;
  ipmitool -I lan -H "$1" -U ADMIN -P "$2" chassis power status;
}

function ipmi-off() {
  ipmitool -I lan -H "$1" -U ADMIN -P "$2" chassis power off;
  sleep 5;
  ipmitool -I lan -H "$1" -U ADMIN -P "$2" chassis power status;
}

function ipmi-reset() {
  ipmitool -I lan -H "$1" -U ADMIN -P "$2" chassis power reset;
  sleep 5;
  ipmitool -I lan -H "$1" -U ADMIN -P "$2" chassis power status;
}