#!/usr/bin/env nodejs
const https = require('https');
const fs = require('fs');

const port = 8080

const options = {
  key: fs.readFileSync('./openssl/cptdagw.org.svr.key'),
  cert: fs.readFileSync('./openssl/cptdagw.org.svr.crt')
};

var server = https.createServer(options);
server.on('request',(req,res)=>{
    res.write(JSON.stringify(req.headers, null, '\t'));
    res.end();
});

server.listen(port,()=>{
    console.log(`Server waiting on port ${port} for you`)
})
