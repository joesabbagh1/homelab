#!/bin/bash
set -e

echo ">>> Starting Kubeadm Cluster Migration..."

# Enable macOS Fork Safety
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# Run the Playbook
ansible-playbook -i inventory.ini site.yml --ask-vault-pass -e @secrets.yml

echo ""
echo ">>> SUCCESS: Cluster is fully deployed!"
echo ">>> Refreshing local configuration..."

# Fix: Ensure the shell uses the correct config for the final check
export KUBECONFIG=$HOME/.kube/config-homelab

echo ">>> Current Cluster Status:"
# This will now work because KUBECONFIG is set and Ansible fixed the IP inside the file
kubectl get nodes

echo ""
echo ">>> Note: You may need to run 'source ~/.zshrc' in other open terminal windows."
