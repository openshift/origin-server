#!/usr/local/bin/node

/**
 * Module dependencies.
 */
var fs = require('fs');
var crypto = require('crypto');

/**
 * ARGV Set
 */
if (process.argv.length < 3) {
  console.log("Usage: node test_client.js <message-size> [<iterations> <secure>]");
  process.exit(-1);
}

var Size = parseInt(process.argv[2].toString().trim()); // the first argument
var MaxIter = process.argv[3] ? parseInt(process.argv[3].toString().trim()) : 20; // the second argument
var Protocol = process.argv[4] ? 'wss': 'ws' // the third argument

var ServerName = 'localhost';
var PortN = 8000;
var WebSocketClient = require('websocket').client;
var client = new WebSocketClient({
  maxReceivedFrameSize: 0x40000000, // 1GiB max frame size
  maxReceivedMessageSize: 0x40000000 // 1GiB max message size
});
client.connect(Protocol + '://' + ServerName + ':' + PortN);

/**
 * Error handler
 */
client.on('connectFailed', function(reason) {
  console.error('connection to the "' + ServerName + '" has broken, reason: [' + reason + ']');
});

client.on('connect', function(connection) {
  var start = undefined;
  var totalTime = 0;
  var i = MaxIter;

  connection.on('error', function(error) {
    console.log("Connection Error: " + error.toString());
  });

  /**
   * Download Event
   */
  connection.on('message', function(message) {
    var time = Date.now() - start;
    console.log('Data size: ' + Size + ', roudtrip time: ' + time + ' ms');
    totalTime += time;
    if (--i) {
      uploadStart(Size);
    } else {
      var ave = totalTime / MaxIter;
      console.log('Average roundtrip time: ' + ave + ' ms');

      /**
       * Transfer ratio: Size(Bytes) / (ave(ms) / 2(roundtrip)) * 1000 = (Bytes per Second)
       * (Bytes per Second) * 8 / 1024 / 1024= (Mbps)
       */
      console.log('Transfer ratio: ' + (Size / ave * 2000).toFixed(1) + '[Bytes per Second] = ' + (Size / ave * 0.0152587890625).toFixed(1) + '[Mbps]');
      process.exit(0);
    }
  });

  /**
   * Upload File
   */
  function uploadStart(size) {
    crypto.randomBytes(size, function(ex, buf) {
      if (ex) throw ex;
      start = Date.now();
      connection.sendBytes(buf);
    });
  }

  uploadStart(Size);
});

