#!/usr/bin/env node
var args, NodeInterval, ni;
args = process.argv.splice(2);
NodeInterval = require('NodeInterval');
fs = require('fs');
var debugDir = "../deploy-debug";
var debugDirExists = false;
try { fs.statSync(debugDir); return true } 
catch (er) { }
if (!debugDirExists) fs.mkdirSync(debugDir, 0777)

ni = new NodeInterval.Watcher({
    watchFolder: '../src/templates/',
    inputFile: ['../src/index.html', '../src/index_uncompressed.html'],
    replacementString: '@templates@',
    outputFile: ['../deploy-prod/index.html', '../deploy-debug/index.html']
});

if (args[0] !== '--no-watch'){
   ni.startWatch();
}

