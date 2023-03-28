# Application Gateway Demo

## Application Gateway with WAF and self signed Server Certificate at frontend and backend

Create application gateway with
- self signed server certificate for frontend and backend (will use the same cert for both).
- waf custom rule (scope httplistener).
- client certificate support on application gateway.


### Deploy 

TODO: ADDSSH Extension installation does not work.
NOTE: Deployment still works.

Define certain variables we will need

~~~ bash
prefix=cptdagw
location=eastus
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv)
myip=$(curl ifconfig.io)
az deployment sub create -n $prefix -l $location --template-file deploy.bicep -p myobjectid=$myobjectid myip=$myip prefix=$prefix

# az group create -n $prefix -l $location
# az deployment group create -n create-vnet -g $prefix --template-file deploy.bicep -p myobjectid=$myobjectid myip=$myip prefix=$prefix
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


### Test Client Certificates

Get the AGW private IP.

~~~ text
az network application-gateway show -n $prefix -g $prefix --query frontendIpConfigurations[].privateIpAddress -o tsv
~~~

Output
~~~ text
10.1.2.4
~~~

Test from azure vm

~~~ bash
vmnodejsid=$(az vm show -g $prefix -n ${prefix}nodejs --query id -o tsv)
az network bastion ssh -n ${prefix}bastion -g $prefix --target-resource-id $vmnodejsid --auth-type "AAD" # login with bastion
# Test via HTTP
curl -H"host: test.cptdagw.org" http://10.1.2.4/ # expect 200 OK
# Test WAF
curl -v -H"host: test.cptdagw.org" "http://10.1.2.4/?cpt=evil" # blocked by WAF 403 Forbidden.
# Test SSL
curl -k -H"host: test.cptdagw.org" https://10.1.2.4/ # expect 400 because client cert is needed.
cd /cptdjsserver # change directory 
# NOTE: We need the curl flag '--resolve' because of [sni](http://www.sigexec.com/posts/curl-and-the-tls-sni-extension/). 
curl -v -k --cert openssl/alice.crt --key openssl/alice.key https://test.cptdagw.org/ --resolve test.cptdagw.org:443:10.1.2.4 # expect 200 OK
# Send request without Client Certificate.
curl -v -k --tlsv1.2 https://test.cptdagw.org/ --resolve test.cptdagw.org:443:10.1.2.4 # expect 400 bad request
# See more details of the ssl handshake by using openssl.
echo quit | openssl s_client -showcerts -connect 10.1.2.4:443 -servername test.cptdagw.org:443 # look for Acceptable client certificate CA names
logout # logout from the current linux vm.
~~~

### Retrieve Logs

~~~ bash
vmip=$(az network nic show -g $prefix -n ${prefix}nodejs --query ipConfigurations[0].privateIpAddress -o tsv) # vm ip
law=$(az monitor log-analytics workspace show -g $prefix -n $prefix --query customerId -o tsv)
waftransid=$(az monitor log-analytics query -w $law --analytics-query 'AzureDiagnostics | where ResourceId contains "APPLICATIONGATEWAY" | where clientIP_s == "'${vmip}'" | where requestQuery_s == "cpt=evil"' --query [].transactionId_g -o tsv)
az monitor log-analytics query -w $law --analytics-query 'AzureDiagnostics | where transactionId_g =="'${waftransid}'"'
~~~

Get web application firewall log record by transaction Id.
In our case we received the transaction id c60bf05a-6102-5a74-a91a-699e00fb954e.
You will get another one which you need to replace on the next command.

NOTE: In case the WAF did not block your request you will recieve a 200 OK. Part of the response will be the http response header "x-appgw-trace-id". 
Use the node.js helper script to format the http header "x-appgw-trace-id" value into GUID format.

## Misc
~~~bash
az deployment operation group list --resource-group $prefix --name $prefix
~~~
### Access azure VMs

~~~ pwsh
az network bastion ssh -n ${prefix}bastion -g $prefix --target-resource-id $vmidlin --auth-type ssh-key --username chpinoto --ssh-key ssh/chpinoto.key
~~~


### Create certificates 

IMPORTANT: This step is optional and if done you will need to update certain files. Instead you can just use the certificates already created under the folder openssl.

Certificates will be created with the help of openssl and a corresponding config file (certificate.cnf).

~~~bash
./create.certificates.sh
~~~

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


## Create Ed25519 Server Ceritifcate with openssl

Links:
- https://security.stackexchange.com/questions/236931/whats-the-deal-with-x25519-support-in-chrome-firefox
- https://www.keyfactor.com/blog/cipher-suites-explained/
- https://blog.pinterjann.is/ed25519-certificates.html

X25519, Algorithms designed by Daniel J. Bernstein et al. are currenlty quite popular and were implemented by many applications. X25519 is now the most widely used key exchange mechanism in TLS 1.3 and the curve has been adopted by software packages such as OpenSSH, Signal and many more.

X25519 is a key exchange - which is supported by browsers. Ed25519 is instead a signature algorithm - which is not supported. X25519 and Ed25519 are thus different things which both use Curve25519.

X25519 (ECDH Key Exchange) with ED25519 (Digital signatures).

TBD


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