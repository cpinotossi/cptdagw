#!/usr/bin/env nodejs
const https = require('https');
const http = require('http');
const fs = require('fs');
const url = require('url');

let args=process.argv;
let color=args[2];

// Object which will be printed on server response
let socketDetails = {
    ladd:'',
    lport:'',
    radd:'',
    rport:''
};

// SSL Port we are going to use
const portSSL = 443

// Option of the SSL server
const optionsSSL = {
  key: fs.readFileSync('./openssl/srv.key'),
  cert: fs.readFileSync('./openssl/srv.crt'),
  requestCert: true,
  rejectUnauthorized: false, // so we can do own error handling
  ca: [
    fs.readFileSync('./openssl/ca.crt')
  ]
};

// Create https server
var serverSSL = https.createServer(optionsSSL);
serverSSL.on('request',(req,res)=>{
    socketDetails.ladd = req.socket.localAddress;
    socketDetails.lport = req.socket.localPort;
    socketDetails.radd = req.socket.remoteAddress;
    socketDetails.rport = req.socket.remotePort;
    res.write(`<body bgcolor="${color}">\n`);
    res.write(`${JSON.stringify(req.headers, null, '\t')}\n`);
    res.write(`${JSON.stringify(socketDetails, null, '\t')}\n`);    
    //Verify if user did send client certificate.
    if (req.socket.authorized){
        res.write(`client-cert:${req.socket.getPeerCertificate().subject.CN}\n`);
    }
    res.write(`</body>\n`);
    res.end();
});
serverSSL.listen(portSSL,'0.0.0.0',()=>{
    console.log(`Server waiting on port ${portSSL} for you`)
})

// Create http server
const port = 80
var server = http.createServer();
server.on('request',(req,res)=>{
    socketDetails.ladd = req.socket.localAddress;
    socketDetails.lport = req.socket.localPort;
    socketDetails.radd = req.socket.remoteAddress;
    socketDetails.rport = req.socket.remotePort;
    res.write(`${JSON.stringify(req.headers, null, '\t')}\n`);
    res.write(`${JSON.stringify(socketDetails, null, '\t')}\n`);   
    res.end();
});

server.listen(port,'0.0.0.0',()=>{
    console.log(`Server waiting on port ${port} for you`)
})
