var  http = require('http');
var  https = require('https');
var  fs = require('fs');
var  ws = require('ws');


function bin2hex (s) {
     var i, l, o = "", n;

     s += "";
     for (i = 0, l = s.length; i < l; i++) {
        n = s.charCodeAt(i).toString(16)
        o += n.length < 2 ? "0" + n : n;
     }

     return o;
}

var createWebSocketServer = function(proto_server) {
   var ws_server = new ws.Server({server: proto_server });
   ws_server.on('connection', function(conn) { 
     console.log("connection = " + conn + ",  headers properties: "); 
       console.log("host = " + conn.upgradeReq.headers.host); 
     // for (var p in conn.upgradeReq.headers) { 
     for (var p in conn) { 
       console.log(p); 
     }
     conn.on('message', function(msg) {
       console.log('got a message: ' + bin2hex(msg) );
       conn.send('message', msg);
     });
   });
   return ws_server;
};

var app8080 = http.createServer(function(req,res) {
  if (req.url == "/500") {
    console.log('returning error 500');
    res.statusCode = 500;
    res.end();
    setTimeout(function() { process.exit(11); }, 100);

  } else if (req.url == "/404") {
    console.log('returning error 404');
    res.statusCode = 404;
    res.end();
  }
  else {
    console.log('got request ' + req.headers.host + req.url);
    res.end('hello world');
  }
});
app8080.listen(8080);
createWebSocketServer(app8080);

var  sslcerts_path = "../sslcerts/";
var  server_name = "localhost";
var ssl_options = {
  key:  fs.readFileSync(sslcerts_path + server_name + ".key"),
  cert: fs.readFileSync(sslcerts_path + server_name + ".crt")
};

var app8443 = https.createServer(ssl_options);
app8443.listen(18443);
createWebSocketServer(app8443);

