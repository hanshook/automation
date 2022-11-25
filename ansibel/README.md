# Ansible playbooks

## Overview

This repository contains Ansible playbooks for:

* Deploing all physical and virtual servers
* Setting up and administrate admin users on all servers
* Installing software and configuring servers
* ...

## Execution

1. Install physical servers.
   Ensure there is a notroot user on all physical servers with sudo rights and that accepts your ssh key for ssh login.
   Also ensure that there is a host_vars/<physical server name>/become.yml vault file with an entry  ```notroot_become_pass: <notroot password on server>```.

2. Setup admin users: ```ansible-playbook admins.yml```

3. Install software, update and configure physical servers: ```ansible-playbook initialize_physical.yml```

4. Setup storage on physical servers: ```ansible-playbook storage.yml```


## Edit vault data

Edit vault. ```export EDITOR=emacs; ansible-vault edit group_vars/all/vault```

Change to your prefered editor in: export EDITOR=/usr/bin/emacs


### Usefull options

Dry-run: ```ansible-playbook <playbook>.yml --check```

Run on a specific host: ```ansible-playbook <playbook>.yml -l inventory_hostname```

Run on a specific group: ```ansible-playbook <playbook>.yml -l servers```

Run on a specific tag: ```ansible-playbook <playbook>.yml --tags nagiosclient```


## Prerequsites

Currently the playbooks will run if gnu pass is installed and there exists an executable file ```~/.bin/ansible-admin-vault-pass.sh```
with the following content:

```
#!/bin/sh
pass show ansible-admin-vault-password

```

To install pass: ```sudo apt-get install pass```

You need a personal GPG key.

If you do not have one generate one with: ```gpg --gen-key```

Create a password store with: ```pass init "...your email from your GPG key"```

Add the ansible-vault-password to the password store with: ```pass insert ansible-vault-password```


Some info on password is found [here](https://www.passwordstore.org/).

Finally add a private (do not check into github) vault file ```group_vars/all/become.yml``` with
your sudo password.

Do this by:

```
touch group_vars/all/become.yml
ansible-vault encrypt group_vars/all/become.yml
export EDITOR=emacs; ansible-vault edit group_vars/all/become.yml

```
Now edit in the following content in the file:

```
ansible_become_pass: <your sudo password here>

```

Finally save the vault file.

Whith this setup it should be possible to run the playbooks (safely) without manually entering sudo passwords and vault passwords.

Note:

You may alternative run the playbooks with ```--ask-become-pass```.

You may also run the playbooks and get prompted for the vault password after chaning the  file ```ansible.cfg```  from


```
...
#ask_vault_pass = True
vault_password_file = ~/.bin/ansible-vault-pass.sh
...

```

to

```
...
ask_vault_pass = True
#vault_password_file = ~/.bin/ansible-vault-pass.sh
...

```
