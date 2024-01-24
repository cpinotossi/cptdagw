# Application Gateway Demo

## WSL bug

~~~bash
sudo hwclock -s
sudo ntpdate time.windows.com
~~~

## Application Gateway with VMSS as backend

~~~ bash
prefix=cptdagw
location=eastus
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv)
myip=$(curl ifconfig.io)
az lock list -g $prefix
az group delete -n $prefix -y
az deployment sub create -n $prefix -l $location --template-file deploy.bicep -p myobjectid=$myobjectid myip=$myip prefix=$prefix
~~~

Connect to VM
~~~bash
# connect to vmss instance blue and verify if server is running
vmssblueid=$(az vmss list-instances -n ${prefix}blue -g $prefix --query [0].id -o tsv)
az network bastion ssh -n ${prefix}bastion -g $prefix --target-resource-id $vmssblueid --auth-type password --username chpinoto
demo!pass123
curl -v localhost:8000/index.html # expect 200 OK and data-bgcolor="3399ff"
sudo PM2_HOME=/etc/.pm2 pm2 logs
logout
# connect to vmss instance blue and verify if server is running
vmssgreenid=$(az vmss list-instances -n ${prefix}green -g $prefix --query [0].id -o tsv)
# az network bastion ssh -n ${prefix}bastion -g $prefix --target-resource-id $vmssgreenid --auth-type AAD
az network bastion ssh -n ${prefix}bastion -g $prefix --target-resource-id $vmssgreenid --auth-type password --username chpinoto
demo!pass123
sudo ps aux | grep pm2 # look for the root etc entry
sudo PM2_HOME=/etc/.pm2 pm2 status
sudo PM2_HOME=/etc/.pm2 pm2 logs
curl -v localhost:8000/index.html # expect 200 OK and data-bgcolor="009900"
sudo -u chpinoto bash # in case you like to act like the local user
logout
~~~

Verify if everything is working

~~~ bash
# Verify health probe
az network application-gateway show-backend-health -n $prefix -g $prefix --query backendAddressPools[].backendHttpSettingsCollection[].servers[]
az network public-ip show -n ${prefix}agw -g $prefix --query ipAddress -o tsv
agwpubipid=$(az network application-gateway show -n $prefix -g $prefix --query frontendIpConfigurations[0].publicIpAddress.id -o tsv)
agwpubip=$(az network public-ip show --ids $agwpubipid --query ipAddress -o tsv)
echo $agwpubip
az network dns zone show -g cptdazdomains -n ${prefix}.org
az network dns record-set a list -g cptdazdomains -z ${prefix}.org
az network dns record-set a delete -g cptdazdomains -z ${prefix}.org  -n ws -y
az network dns record-set a add-record -g cptdazdomains -z ${prefix}.org  -n ws -a $agwpubip --ttl 10
az network dns record-set a update -g cptdazdomains -z ${prefix}.org  -n ws -a $agwpubip --ttl 10

dig ws.${prefix}.org 
curl http://cptdagw.eastus.cloudapp.azure.com:8000/index.html
~~~

# misc

### Application Gateway and Websockets

It looks like the Application Gateway does disconnect Websocket connection after ~50sec if no message are send via the connection:

~~~text
Websocket: connected: Mon, 03 Apr 2023 13:38:15 GMT
websocket.js:30 {"x":138,"y":215}
websocket.js:62 Websocket: disconnected: Mon, 03 Apr 2023 13:38:52 GMT
websocket.js:63 Websocket: connection duration: 0.61555 min

try connect: ws://ws.cptdagw.org:80: 1
websocket.js:70 Websocket: connected: Mon, 03 Apr 2023 13:41:38 GMT
websocket.js:30 {"x":364,"y":334}
websocket.js:62 Websocket: disconnected: Mon, 03 Apr 2023 13:42:13 GMT
websocket.js:63 Websocket: connection duration: 0.5749666666666666 min
~~~

### Restart application gateway

Based on https://docs.microsoft.com/en-us/powershell/module/az.network/start-azapplicationgateway?view=azps-7.3.0

~~~bash
az network application-gateway stop -n $prefix -g $prefix
az network application-gateway start -n $prefix -g $prefix 
~~~
~~~ pwsh
$prefix="cptdagw"
$appgw=Get-AzApplicationGateway -n $prefix -g $prefix
Stop-AzApplicationGateway -ApplicationGateway $prefix
Start-AzApplicationGateway -ApplicationGateway $prefix
~~~

### Get application gateway public ip

NOTE:
You can get the public IP as follow

~~~bash
az network public-ip show -n ${prefix}agw -g $rg --query ipAddress -o tsv
~~~


### Clean up
~~~bash
az group delete -n $prefix -y
~~~

## path rules limits
~~~ bash
prefix=cptdazagw
location=eastus
myobjectid=$(az ad user list --query '[?displayName==`chpinoto`].id' -o tsv)
myip=$(curl ifconfig.io)
az group create -n $prefix -y
az deployment group create -g $prefix -n $prefix --template-file deploy2.bicep
~~~


### Links

- https://github.com/julie-ng/nodejs-certificate-auth



### Git

~~~ text
git status
git add *
git commit -m"Add client cert pem in forward header"
git push origin master

git tag //list local repo tags
git ls-remote --tags origin //list remote repo tags
git fetch --all --tags // get all remote tags into my local repo
git log --oneline --decorate // List commits
git log --pretty=oneline //list commits
git tag -a v2 b20e80a //tag my last commit
git checkout v1
git switch - //switch back to current version
co //Push all my local tags
git push origin <tagname> //Push a specific tag
git commit -m"not transient"
git tag v1
git push origin v1
git tag -l
git fetch --tags
git clone -b <git-tagname> <repository-url> 
git checkout vmss.zerodowntime
~~~