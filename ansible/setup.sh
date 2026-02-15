#!/bin/bash

echo ">>> Starting K3s Cluster Deployment (Vault Enabled)..."

# --ask-vault-pass: Prompts you for the master password once
# -e @secrets.yml: Tells Ansible to load the encrypted variables
ansible-playbook -i inventory.ini site.yml --ask-vault-pass -e @secrets.yml

if [ $? -eq 0 ]; then
	echo ">>> Success! Verifying nodes..."
	sleep 5
	ssh -i ~/.ssh/homelab_id node1@192.168.0.10 "sudo kubectl get nodes"
else
	echo ">>> Deployment failed. Check your Vault password or node connectivity."
fi
