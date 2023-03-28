# Application Gateway Demo

## Application Gateway with VMSS as backend

~~~ bash
prefix=cptdagw
location=eastus
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv)
myip=$(curl ifconfig.io)
az deployment sub create -n $prefix -l $location --template-file deploy.bicep -p myobjectid=$myobjectid myip=$myip prefix=$prefix
~~~

Connect to VM
~~~bash
vmnodejsid=$(az vm show -g $prefix -n ${prefix}nodejs --query id -o tsv)
az network bastion ssh -n ${prefix}bastion -g $prefix --target-resource-id $vmnodejsid --auth-type "AAD"
curl localhost:8080 # local request
curl -v http://10.1.2.4/ -H"host: test.cptdagw.org" # via AGW
curl -v -k https://10.1.2.4/ -H"host: test.cptdagw.org" # via AGW
# NOTE: We need the curl flag '--resolve' because of [sni](http://www.sigexec.com/posts/curl-and-the-tls-sni-extension/). 
curl -v -k https://test.cptdagw.org/ --resolve test.cptdagw.org:443:10.1.2.4 # expect 200 OK
curl -v -k --cert openssl/alice.crt --key openssl/alice.key https://test.cptdagw.org/ --resolve test.cptdagw.org:443:10.0.2.4 # expect 200 OK
sudo -u chpinoto bash # in case you like to act like the local user
cd /cptdjsserver

sudo ps aux | grep pm2 # look for the root etc entry
sudo PM2_HOME=/etc/.pm2 pm2 status
logout
~~~

Verify if backend is working

~~~ bash
az network application-gateway show-backend-health -n $prefix -g $prefix --query backendAddressPools[].backendHttpSettingsCollection[].servers[]
~~~

Outcome:
We expect two entries one for our http and one for our tls backend (both via the same IP).


### Restart application gateway

Based on https://docs.microsoft.com/en-us/powershell/module/az.network/start-azapplicationgateway?view=azps-7.3.0

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

### Test client certificate locally 

~~~ text
node server.js
~~~

Open a new shell.

~~~ text
curl -v -k --tlsv1.2 --cert openssl/alice.crt --key openssl/alice.key https://127.0.0.1/
~~~

Get more details of the tls handshake via openssl.

~~~ text
echo quit | openssl s_client -showcerts -connect 127.0.0.1:443
echo quit | openssl s_client -showcerts -tlsextdebug -connect 193.99.144.85:443 //Heise.de
openssl s_client -tls1_2 -connect 10.217.0.202:2003 -showcerts
~~~

### Retrieve certificate details openssl

~~~ text
openssl x509 -in openssl/alice.crt -noout -subject -issuer
openssl x509 -in openssl/alice.crt -subject -issuer
openssl x509 -in openssl/alice.crt -text
openssl x509 -in openssl/ca.crt -text
openssl x509 -in openssl/srv.crt -noout -text
openssl x509 --help
~~~

Extract the certificate from server

~~~ text
echo quit | openssl s_client -showcerts -servername localhost -connect localhost:443 > testcacert.pem
~~~

Show certification chain
~~~ text
echo quit | openssl s_client -connect localhost:443 -showcerts | grep "^ "
~~~


az group delete -n $rg -y


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
~~~