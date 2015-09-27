function ssh-mdc() {
	/usr/bin/ssh -t "$@" 'bash -s
	# REQUIRED PACKAGE INSTALL
	if [ -f /etc/redhat-release ]; then
		yum -y install screen curl;
	else
		apt-get -y install screen curl;
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
	/usr/bin/ssh -t "$@" 'bash -s
	# REQUIRED PACKAGE INSTALL
	if [ -f /etc/redhat-release ]; then
		yum -y install screen curl;
	else
		apt-get -y install screen curl;
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

function function-update() {
	curl -O https://raw.githubusercontent.com/mitapia/sh/master/functions.sh;
	source functions.sh;
}


function ssh-test () {
     # get list of servers to use
     while read login; do
          # it is recommended to set up ssh keys for the servers in testing_server.list to avoid password prompt
          # connect to server and run script
          ssh-mdc "$login";
          echo "Completed for " "$login";

     done < testing_servers.list  # each line must be 'user@ip'
}
