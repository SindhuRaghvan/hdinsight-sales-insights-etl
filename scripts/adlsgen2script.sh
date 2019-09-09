#!/bin/bash
# create service principal, assign role, save variables
az ad sp create-for-rbac --role "Storage Blob Data Contributor" --scope "subscriptions/<SUBSCRIPTION ID>/resourceGroups/<RESOURCE GROUP>/providers/Microsoft.Storage/storageAccounts/<ADLSGEN2 STORAGER ACCOUNT>" > serviceprincipal.json
CLIENT_ID=$(cat serviceprincipal.json | jq -r '.appId')
CLIENT_SECRET=$(cat serviceprincipal.json | jq -r '.password')
TENANT_NAME=$(cat serviceprincipal.json | jq -r '.tenant')
STORAGE_ACCOUNT_NAME=<YOUR_STORAGE_ACCOUNT_NAME>
# get authorization token
ACCESS_TOKEN=$(curl -X POST -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=$CLIENT_ID" --data-urlencode "client_secret=$CLIENT_SECRET" --data-urlencode "scope=https://storage.azure.com/.default" --data-urlencode "grant_type=client_credentials" "https://login.microsoftonline.com/$TENANT_NAME/oauth2/v2.0/token" | jq -r ".access_token")
#create files FS
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files?resource=filesystem"
curl -i -X PATCH -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "x-ms-acl: user::rwx,group::r-x,other::--x,default:user::rwx,default:group::r-x,default:other::--x" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/?action=setAccessControl"
# create correct folder structure
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/data?resource=directory"
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/transformed?resource=directory"
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf?resource=directory"
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf/files?resource=directory"
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf/pyFiles?resource=directory"
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf/jars?resource=directory"
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf/archives?resource=directory"
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf/logs?resource=directory"
curl -i -X PUT -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf/sparktransform.py?resource=file"
#create the sparktransform.py file
cat sparktransform.py | curl -i -X PATCH -H "x-ms-version: 2018-11-09" -H "Authorization: Bearer $ACCESS_TOKEN" --data-binary @- "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf/sparktransform.py?action=append&position=0"
curl -i -H "x-ms-version: 2018-11-09" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf/sparktransform.py"
FILENUM=$(wc -c < sparktransform.py)
curl -i -X PATCH -H "x-ms-version: 2018-11-09" -H "content-length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" "https://$STORAGE_ACCOUNT_NAME.dfs.core.windows.net/files/adf/sparktransform.py?action=flush&position=$FILENUM"