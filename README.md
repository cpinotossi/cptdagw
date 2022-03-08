# Application Gateway Demo

## Application Gateway with WAF and self signed Server Certificate at frontend and backend

Create application gateway with
- self signed server certificate for frontend and backend (will use the same cert for both).
- waf custom rule (scope httplistener).
- client certificate support on application gateway.


### Deploy 

Define certain variables we will need
~~~ text
prefix=cptdagw
rg=${prefix}
myobjectid=$(az ad user list --query '[?displayName==`ga`].objectId' -o tsv)
myip=$(curl ifconfig.io)
az group create -n $rg -l eastus
az deployment group create -n create-vnet -g $rg --template-file bicep/deploy.bicep -p myobjectid=$myobjectid myip=$myip prefix=$prefix
~~~

Verify if backend is working.

~~~ text
az network application-gateway show-backend-health -n $prefix -g $rg --query backendAddressPools[].backendHttpSettingsCollection[].servers[]
~~~

### Test Client Certificates

Get the AGW private IP.

~~~ text
az network application-gateway show -n $prefix -g $rg --query frontendIpConfigurations[].privateIpAddress -o tsv
~~~


#### SSH into grafana VM via azure bastion client

> IMPORTANT: The following commands need to executed on powershell.

~~~ pwsh
$prefix="cptdagw"
$vmidlin=az vm show -g $prefix -n ${prefix}lin --query id -o tsv
az network bastion ssh -n ${prefix}bastion -g $prefix --target-resource-id $vmidlin --auth-type "AAD"
~~~

Or use ssh without AAD

~~~ pwsh
az network bastion ssh -n ${prefix}bastion -g $prefix --target-resource-id $vmidlin --auth-type ssh-key --username chpinoto --ssh-key ssh/chpinoto.key
~~~

Inside the vm send a request to the private IP of the agw via curl with a valid Client Certificate.

~~~ bash
cd /
curl -v -k --cert openssl/alice.crt --key openssl/alice.key https://test.cptdagw.org/ --resolve test.cptdagw.org:443:10.0.2.4
~~~

> NOTE: We need the curl flag '--resolve' because of [sni](http://www.sigexec.com/posts/curl-and-the-tls-sni-extension/). 

Output should be HTTP 200 OK.

~~~ text
HTTP/1.1 200 OK
~~~

Send request without Client Certificate.

~~~ text
curl -v -k --tlsv1.2 https://test.cptdagw.org/ --resolve test.cptdagw.org:443:10.0.2.4
~~~

You should receive an 400 Bad Request.

~~~ text
HTTP/1.1 400 Bad Request

<html>
<head><title>400 No required SSL certificate was sent</title></head>
<body>
<center><h1>400 Bad Request</h1></center>
<center>No required SSL certificate was sent</center>
<hr><center>Microsoft-Azure-Application-Gateway/v2</center>
</body>
</html>
~~~

See more details of the ssl handshake by using openssl.

~~~ bash
echo quit | openssl s_client -showcerts -connect 10.0.2.4:443 -servername test.cptdagw.org:443
~~~

There you can see which client certificate CAs our server supports:

~~~ text
---
Acceptable client certificate CA names
CN = cptdagw.org CA
~~~

### Test WAF

Without the query parameter cpt=evil you should receive an 200 OK.

~~~ text
curl -H"host: test.cptdagw.org" http://10.0.2.4/
~~~

Blocked by WAF, you should receive an 403 Forbidden because of the query parameter cpt=evil.

~~~ text
curl -v -H"host: test.cptdagw.org" "http://10.0.2.4/?cpt=evil"
~~~

Get the log analytics workspace id.

Get the VM ip.

~~~ text
vm=$(az vm list -g $rg --query [].name -o tsv)
az network nic show -g $rg -n $vm --query ipConfigurations[0].privateIpAddress -o tsv
~~~

In our case the ip has been "10.0.0.4", in case you got a differnt one, replace it inside the following command.

~~~bash
law=$(az monitor log-analytics workspace show -g cptdagw -n cptdagw --query customerId -o tsv)
az monitor log-analytics query -w $law --analytics-query 'AzureDiagnostics | where ResourceId contains "APPLICATIONGATEWAY" | where clientIP_s == "10.0.0.4" | where requestQuery_s == "cpt=evil"' --query [].transactionId_g -o tsv
~~~


Get web application firewall log record by transaction Id.
In our case we received the transaction id c60bf05a-6102-5a74-a91a-699e00fb954e.
You will get another one which you need to replace on the next command.

~~~bash
az monitor log-analytics query -w $law --analytics-query 'AzureDiagnostics | where transactionId_g =="c60bf05a-6102-5a74-a91a-699e00fb954e"'
~~~


In case the WAF did not block your request you will recieve a 200 OK. Part of the response will be the http response header "x-appgw-trace-id". 
Use the node.js helper script to format the http header "x-appgw-trace-id" value into GUID format.

~~~
node guidformater.js fbb1e0f840243e440e74de29ea5581bc
~~~

Get application gateway log record by transaction id.

~~~bash
az monitor log-analytics query -w $law --analytics-query 'AzureDiagnostics | where transactionId_g=="fbb1e0f8-4024-3e44-0e74-de29ea5581bc"'
~~~

## Misc

### Create certificates 

IMPORTANT: This step is optional and if done you will need to update certain files. Instead you can just use the certificates already created under the folder openssl.

Certificates will be created with the help of openssl and a corresponding config file (certificate.cnf).

~~~bash
./create.certificates.sh
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


## Git misc

~~~ text
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