##################################
### Run in azure cloud shell !!! #
##################################
# NOTE: This is based on the https://docs.microsoft.com/sv-se/azure/aks/azure-files-volume
# TITLE: 'Manually create and use a volume with Azure Files share in Azure Kubernetes Service (AKS)'

# COMMON FOR BOTH IMAGES AND BACKUP
###################################

# Define common storeage location
AKS_LOCATION=northeurope

# Define resource group
AKS_RESOURCE_GROUP=tastebudsstoragegroup

# Create a resource group
az group create --name $AKS_RESOURCE_GROUP --location $AKS_LOCATION

# Define common storageaccount
AKS_STORAGE_ACCOUNT_NAME=tastebudsstorageaccount

# Create a storage account
az storage account create -n $AKS_STORAGE_ACCOUNT_NAME -g $AKS_RESOURCE_GROUP -l $AKS_LOCATION --sku Standard_LRS

# Export the connection string as an environment variable, this is used when creating the Azure file share
export TASTEBUDS_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string -n $AKS_STORAGE_ACCOUNT_NAME -g $AKS_RESOURCE_GROUP -o tsv)

# Get storage account key
STORAGE_KEY=$(az storage account keys list --resource-group $AKS_RESOURCE_GROUP --account-name $AKS_STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv)

# Create secret for access to the storage account
kubectl create secret generic tastebuds-storage-secret --from-literal=azurestorageaccountname=$AKS_STORAGE_ACCOUNT_NAME --from-literal=azurestorageaccountkey=$STORAGE_KEY

# Echo storage account name and key
echo Location:                   $AKS_LOCATION
echo Resource group:             $AKS_RESOURCE_GROUP
echo Storage account name:       $AKS_STORAGE_ACCOUNT_NAME
echo Storage account connection: $TASTEBUDS_STORAGE_CONNECTION_STRING
echo Storage account key:        $STORAGE_KEY


# SPECIFIC FOR IMAGES STORAGE
#############################

# Define share name for images
AKS_IMAGES_SHARE_NAME=tastebudsimages

# Create the file share - per fileshare
az storage share create -n $AKS_IMAGES_SHARE_NAME --connection-string $TASTEBUDS_STORAGE_CONNECTION_STRING


# SPECIFIC FOR BACKUP STORAGE
#############################

# Define share name for images
AKS_BACKUP_SHARE_NAME=tastebudsbackup

# Create the file share - per fileshare
az storage share create -n $AKS_BACKUP_SHARE_NAME --connection-string $TASTEBUDS_STORAGE_CONNECTION_STRING

# Setup of cluster and storage shares finished!
###############################################


# Apply the configmap for database access
kubectl apply -f tastebuds-configmap.yaml

# Apply persistent voluems and persistent volume claimes for images and backup
kubectl apply -f imagestore-images-azurefile-pv.yaml
kubectl apply -f imagestore-images-azurefile-pvc.yaml

kubectl apply -f imagestore-backup-azurefile-pv.yaml
kubectl apply -f imagestore-backup-azurefile-pvc.yaml

kubectl get pv
kubectl get pvc

# Apply the imagestore for azurefiles
kubectl apply -f imagestore-stateful-azurefile.yaml
kubectl get all
kubectl describe pod imagestore-0

# Apply all the other deploy, steteful and service yaml files
kubectl apply -f imagestore-service.yaml

kubectl apply -f tastebudsadm-deploy.yaml
kubectl apply -f tastebudsadm-service.yaml

kubectl apply -f tastebudsback-deploy.yaml
kubectl apply -f tastebudsback-service.yaml

kubectl apply -f tastebudsmysql-service.yaml
kubectl apply -f tastebudsmysql-stateful.yaml


# Logg in and check the azurefile images and backup
#----------------------------------------------------------------
uno@Azure:~$ kubectl exec --stdin --tty imagestore-0 -- /bin/bash
node@imagestore-0:~/app$ ls -l
total 72
-rwxr-xr-x 1 node node  1083 Oct 21 09:27 authenticate.js
drwxrwxrwx 2 node node     0 Feb  2 15:15 backup
-rwxr-xr-x 1 node node   491 Jan 17 16:17 backup.sh
-rwxr-xr-x 1 node node   404 Dec 30 14:39 config.js
-rwxr-xr-x 1 node node   246 Oct 21 09:23 database.js
drwxrwxrwx 2 node node     0 Feb  2 15:15 images
-rwxr-xr-x 1 node node  1257 Dec 30 10:33 index.js
drwxr-xr-x 1 node node  4096 Jan 15 13:35 node_modules
-rwxr-xr-x 1 root root 22752 Oct 10 13:17 package-lock.json
-rwxr-xr-x 1 root root   397 Dec 22 11:52 package.json
-rwxr-xr-x 1 node node   607 Jan 17 16:23 restore.sh
-rwxr-xr-x 1 node node   259 Sep  1 14:34 security.js
-rwxr-xr-x 1 node node   846 Dec 30 10:31 utils.js
-rwxr-xr-x 1 node node  4256 Sep  1 14:32 wait-for-it.sh
node@imagestore-0:~/app$ ls -l images
total 0
node@imagestore-0:~/app$ echo "Uno image" > images/uno.jpg
node@imagestore-0:~/app$ ls -l images
total 1
-rwxrwxrwx 1 node node 10 Feb  2 15:18 uno.jpg
node@imagestore-0:~/app$ ./backup.sh
Create backup of all images to the directory backup/20210202.
Create the backup directory backup/20210202.
mkdir: created directory 'backup/20210202'
Backup all files in the images directory to backup/20210202.
'images/uno.jpg' -> 'backup/20210202/uno.jpg'
Backup is created! ---
node@imagestore-0:~/app$ ls -l backup/20210202/
total 1
-rwxrwxrwx 1 node node 10 Feb  2 15:19 uno.jpg
node@imagestore-0:~/app$ exit
exit
uno@Azure:~$ kubectl exec --stdin --tty imagestore-1 -- /bin/bash
node@imagestore-1:~/app$ ls -l
total 72
-rwxr-xr-x 1 node node  1083 Oct 21 09:27 authenticate.js
drwxrwxrwx 2 node node     0 Feb  2 15:15 backup
-rwxr-xr-x 1 node node   491 Jan 17 16:17 backup.sh
-rwxr-xr-x 1 node node   404 Dec 30 14:39 config.js
-rwxr-xr-x 1 node node   246 Oct 21 09:23 database.js
drwxrwxrwx 2 node node     0 Feb  2 15:15 images
-rwxr-xr-x 1 node node  1257 Dec 30 10:33 index.js
drwxr-xr-x 1 node node  4096 Jan 15 13:35 node_modules
-rwxr-xr-x 1 root root 22752 Oct 10 13:17 package-lock.json
-rwxr-xr-x 1 root root   397 Dec 22 11:52 package.json
-rwxr-xr-x 1 node node   607 Jan 17 16:23 restore.sh
-rwxr-xr-x 1 node node   259 Sep  1 14:34 security.js
-rwxr-xr-x 1 node node   846 Dec 30 10:31 utils.js
-rwxr-xr-x 1 node node  4256 Sep  1 14:32 wait-for-it.sh
node@imagestore-1:~/app$ ls -l imgaes
ls: cannot access 'imgaes': No such file or directory
node@imagestore-1:~/app$ ls -l images
total 1
-rwxrwxrwx 1 node node 10 Feb  2 15:18 uno.jpg
node@imagestore-1:~/app$ rm images/uno.jpg
node@imagestore-1:~/app$ ls -l backup
total 0
drwxrwxrwx 2 node node 0 Feb  2 15:19 20210202
node@imagestore-1:~/app$ ls -l backup/20210202/
total 1
-rwxrwxrwx 1 node node 10 Feb  2 15:19 uno.jpg
node@imagestore-1:~/app$ ./restore.sh 20210202
Restore all images from the backup directory backup/20210202.
Directory backup/20210202 exists.
Remove all images in images directory.
rm: cannot remove 'images/*': No such file or directory
Restore all images from backup backup/20210202 to images directory.
'backup/20210202/uno.jpg' -> 'images/uno.jpg'
Images restored from backup.
node@imagestore-1:~/app$ ls -l images/
total 1
-rwxrwxrwx 1 node node 10 Feb  2 15:20 uno.jpg
node@imagestore-1:~/app$ exit
exit
uno@Azure:~$ kubectl exec --stdin --tty imagestore-0 -- /bin/bash
node@imagestore-0:~/app$ ls -l images
total 1
-rwxrwxrwx 1 node node 10 Feb  2 15:20 uno.jpg
node@imagestore-0:~/app$ exit
exit
uno@Azure:~$
#----------------------------------------------------------------


# OPTIONALY: Delete the storage account resoured group
# NOTE: Sometime need to be run multipel times!!!
#####################################################################################
az group delete --name tastebudsstoragegroup --yes --no-wait
