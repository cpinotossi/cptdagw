#!/usr/bin/env nodejs
const https = require('https');
const http = require('http');
const fs = require('fs');

const portSSL = 443
const options = {
  key: fs.readFileSync('./openssl/svr.key'),
  cert: fs.readFileSync('./openssl/svr.crt')
};
var serverSSL = https.createServer(options);
serverSSL.on('request',(req,res)=>{
    res.write(JSON.stringify(req.headers, null, '\t'));
    res.end();
});
serverSSL.listen(portSSL,()=>{
    console.log(`Server waiting on port ${portSSL} for you`)
})

const port = 80
var server = http.createServer();
server.on('request',(req,res)=>{
    res.write(JSON.stringify(req.headers, null, '\t'));
    res.end();
});

server.listen(port,()=>{
    console.log(`Server waiting on port ${port} for you`)
})
