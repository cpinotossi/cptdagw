# Create Key of CA
openssl genrsa -out openssl/ca.key 2048
# Create CA Certificate
openssl req -x509 -new -nodes -key openssl/ca.key -sha256 -days 365 -out openssl/ca.crt -config certificate.cnf -extensions v3_ca -subj "/CN=cptdagw.org CA"
# Create Key for Server Certificate
openssl genrsa -out openssl/svr.key 2048
# Create CSR for Server Ceritifcate
openssl req -new -key openssl/svr.key -out openssl/svr.csr -config certificate.cnf -extensions v3_req
# Sign Server Ceritifcate CSR with CA Certificate Key
openssl x509 -req -in openssl/svr.csr -CA openssl/ca.crt -CAkey openssl/ca.key -CAcreateserial -out openssl/svr.crt -days 365 -sha256 -extfile certificate.cnf -extensions v3_req
# Bundle Server Certificate and CA Certificate chain inside pkcs format.
openssl pkcs12 -export -inkey openssl/svr.key -in openssl/svr.crt -certfile openssl/ca.crt -out openssl/svr.pfx -password pass:test123!
# Copy copy pkcs and change extension to cer 
# cp openssl/cptdagw.org.svr.crt openssl/cptdagw.org.svr.cer
# openssl pkcs12 -in openssl/cptdagw.org.svr.pfx -out openssl/cptdagw.org.svr.pfx.pem -password pass:test123! -passin pass:test123! -passout pass:test123!
# base64 openssl/cptdagw.org.svr.pfx.pem > openssl/cptdagw.org.svr.pfx.pem.base64 
# Encode pkcs with base64 so we can provide it to azure application gateway inside bicep
# base64 cptdagw.org.svr.pfx > cptdagw.org.svr.pfx.base64 
echo '--Output result--'
echo '--CA Certificate--'
openssl x509 -in openssl/ca.crt -subject -noout
echo '--Server Certificate--'
openssl x509 -in openssl/svr.crt -subject -noout