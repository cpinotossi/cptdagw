# Create Key of CA
openssl genrsa -out openssl/test.ca.key 4096 
# Alternative way to create key: openssl ecparam -out contoso.key -name prime256v1 -genkey (source: https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/application-gateway/self-signed-certificates.md)
# Create CA Certificate
openssl req \
    -x509 \
    -new \
    -nodes \
    -key openssl/ca.key \
    -sha256 \
    -days 365 \
    -config certificate.cnf \
    -extensions v3_ca \
    -subj "/CN=cptdagw.org CA" \
    -out openssl/ca.crt \

# Create Key for Server Certificate
openssl genrsa -out openssl/srv.key 4096
# Create CSR for Server Ceritifcate
openssl req \
    -new \
    -key openssl/srv.key \
    -out openssl/srv.csr \
    -extensions v3_req \
    -config certificate.cnf
# Sign Server Ceritifcate CSR with CA Certificate Key
openssl x509 \
    -req \
    -in openssl/srv.csr \
    -CA openssl/ca.crt \
    -CAkey openssl/ca.key \
    -CAcreateserial \
    -out openssl/srv.crt \
    -days 365 \
    -sha256 \
    -extfile certificate.cnf \
    -extensions v3_req
# Bundle Server Certificate and CA Certificate chain inside pkcs format.
openssl pkcs12 \
    -export \
    -inkey openssl/srv.key \
    -in openssl/srv.crt \
    -certfile openssl/ca.crt \
    -out openssl/srv.pfx \
    -password pass:test123!

# Copy copy pkcs and change extension to cer 
# cp openssl/cptdagw.org.srv.crt openssl/cptdagw.org.srv.cer
# openssl pkcs12 -in openssl/cptdagw.org.srv.pfx -out openssl/cptdagw.org.srv.pfx.pem -password pass:test123! -passin pass:test123! -passout pass:test123!
# base64 openssl/cptdagw.org.srv.pfx.pem > openssl/cptdagw.org.srv.pfx.pem.base64 
# Encode pkcs with base64 so we can provide it to azure application gateway inside bicep
# base64 cptdagw.org.srv.pfx > cptdagw.org.srv.pfx.base64 

# Create Client Certificate
# generate ca signed (valid) certifcate
openssl req \
	-newkey rsa:4096 \
	-keyout openssl/alice.key \
	-out openssl/alice.csr \
	-nodes \
	-days 365 \
	-subj "/CN=alice.cptdagw.org"

# sign with ca
openssl x509 \
	-req \
	-in openssl/alice.csr \
	-CA openssl/ca.crt \
	-CAkey openssl/ca.key \
	-out openssl/alice.crt \
	-set_serial 01 \
	-days 365

echo '--CA Certificate--'
openssl x509 -in openssl/ca.crt -subject -noout
echo '--Server Certificate--'
openssl x509 -in openssl/srv.crt -subject -noout
echo '--Client Certificate--'
openssl x509 -in openssl/alice.crt -subject -noout