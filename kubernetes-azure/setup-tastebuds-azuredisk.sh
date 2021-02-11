##################################
### Run in azure cloud shell !!! #
##################################

# Apply the configmap for database access
kubectl apply -f tastebuds-configmap.yaml

# Apply the imagestore for azurefiles
kubectl apply -f imagestore-stateful-azuredisk.yaml
kubectl get pv
kubectl get pvc
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
#----------------------------------------------------------------
