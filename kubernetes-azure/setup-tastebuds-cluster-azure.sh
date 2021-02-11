##################################
### Run in azure cloud shell !!! #
##################################

# Create resource group, cluster, get credentials and check kubernetes node!
############################################################################

# Skapa resource group
az group create --name TasteBuds --location northeurope

# Skapa ett AKS kubernetes kluster med 1 node med monitorering och generering av SSH keys
az aks create --resource-group TasteBuds --name TasteBudsCluster --node-count 1 --enable-addons monitoring --generate-ssh-keys

# Download credentials and configuration for kubectl command 
az aks get-credentials --resource-group TasteBuds --name TasteBudsCluster

# Get info about cluster nodes
kubectl get nodes

# To run with azuredisk one replica - follow setup-tastebuds-azuredisk.sh

# To run with azurefile multiple replicas - follow setup-tastebuds-azurefile.sh

# Shutdown the resource group for the cluster
# NOTE: Sometime need to be run multipel times!!!
#####################################################################################
az group delete --name TasteBuds --yes --no-wait
