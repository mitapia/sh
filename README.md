# sh
random work scripts


For first time use copy and paste the following line into your shelladmin: 
`curl -O https://raw.githubusercontent.com/mitapia/sh/master/functions.sh && echo "source ~/functions.sh" >> .bashrc && source .bashrc`

Afterwards updates can be performed by simply running `functions-update`.
If you have suggestions/request to improve an existing script or a brand new script feel free to email me at mitapia@softlayer.com

### MDC script
To perform a full MDC run `ssh-mdc {user}@{ip-address}`

If you first wish to simply see the cummands that `ssh-mdc` will run then run `ssh-mdc-simulate`.  No actual change occurs when running this command.
