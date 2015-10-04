# sh
random work scripts


For first time use copy and paste the following line into your shelladmin: 
`curl -O https://raw.githubusercontent.com/mitapia/sh/master/functions.sh && echo "source ~/functions.sh" >> .bashrc && source .bashrc`

Afterwards updates can be performed by simply running `functions-update`.
If you have suggestions/request to improve an existing script or a brand new script feel free to email me at mitapia@softlayer.com

---
### MDC script
To perform a full MDC run `ssh-mdc {user}@{ip-address}`

If you first wish to simply see the cummands that `ssh-mdc` will run then run `ssh-mdc-simulate`.  No actual change occurs when running this command.

---
### Misc
`ssh-verify-raid`
> Use to print out commonly used stats from RAID card, if one available.

`ssh-rainbow`
> When you log in throug ssh, it will display the prompt in a veriety of colors. Resets after exit.
