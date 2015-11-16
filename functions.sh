function ssh-mdc() {
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

  link=https://raw.githubusercontent.com/mitapia/sh/master/mdc.sh
  script=mdc.sh
  
  # download script
  curl "$link" -o "$script";
  chmod +x "$script";
  
  # create screen
  screen -d -m -L -S mdc;
  # run script on screen
  screen -S mdc -p 0 -X exec ./"$script";
  # attach to screen
  screen -S mdc -r;
  
  rm "$script";'
}

function ssh-mdc-simulate() {
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

  link=https://raw.githubusercontent.com/mitapia/sh/master/mdc_simulate.sh
  script=mdc.sh
  
  # download script
  curl "$link" -o "$script";
  chmod +x "$script";
  
  # create screen
  screen -d -m -L -S mdc;
  # run script on screen
  screen -S mdc -p 0 -X exec ./"$script";
  # attach to screen
  screen -S mdc -r;
  
  rm "$script";'
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