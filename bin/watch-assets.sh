#!/usr/bin/env node
var fs = require('fs');
var debugDir = "../deploy-debug";
var debugDirExists = false;
try { fs.statSync(debugDir); debugDirExists = true } 
catch (er) { }
if (!debugDirExists) fs.mkdirSync(debugDir, 0777);

var sourceFolder = '../src/images';
var destinationFolder = '../deploy-debug'; 
var updateTargetTimeout;
function folderChange(){
	if (updateTargetTimeout) clearTimeout(updateTargetTimeout);
	updateTargetTimeout = setTimeout(copyFolder, 500);
}
function copyFolder(){
	require('child_process').spawn('cp', ['-R', sourceFolder, destinationFolder])
	console.log("recopied folder");
}
var isDirty = false;
var watcher = require('watch-tree').watchTree(sourceFolder, {'sample-rate': 50, ignore:'.DS_Store'});
watcher.on('fileDeleted', function(path) {
    console.log("deleted " + path + "!");
	folderChange();
});
watcher.on('fileCreated', function(path) {
    console.log("created " + path + "!");
	folderChange();
});
watcher.on('fileModified', function(path) {
    console.log("modified " + path + "!");
	folderChange();
});