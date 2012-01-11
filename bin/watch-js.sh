#!/usr/bin/env node
/*
this script appends the javascript src list found in src/js/list.txt into /deploy-debug/index.html whenever the javascript list file is modified. The file paths are listed in the order they should be included. 
a sym link /deploy-debug/js/ folder points to /src/js/ so no copying of actual files are needed for production builds the jakefile will uglify and concat the js files from this same list into /deploy-prod/js/index.js
THIS SCRIPT IS NOT CURRENTLY USED AS WE ARE USING A SYM LINK CURRENTLY.
*/
var fs = require('fs');
var debugDir = "../deploy-debug";
var jsListPath = "../src/js/list.txt";

function copyFilesSync(srcFile, destFile) {
	var BUF_LENGTH, buff, bytesRead, fdr, fdw, pos;
	BUF_LENGTH = 64 * 1024;
	buff = new Buffer(BUF_LENGTH);
	fdr = fs.openSync(srcFile, 'r');
	fdw = fs.openSync(destFile, 'w');
	bytesRead = 1;
	pos = 0;
	while (bytesRead > 0) {
	  bytesRead = fs.readSync(fdr, buff, 0, BUF_LENGTH, pos);
	  fs.writeSync(fdw, buff, 0, bytesRead);
	  pos += bytesRead;
	}
	fs.closeSync(fdr);
	return fs.closeSync(fdw);
}
function updateDebugIndexFile(){
	copyFilesSync('../src/index.html', debugDir+'/index.html');
	//require('child_process').spawn('cp', ['../src/index.html', debugDir]);
	var jsList = fs.readFileSync(jsListPath, "utf8");
	var scripts = "";
	jsList.split(/\r?\n/).forEach(function (line) {
		scripts+='<script src="'+line+'"></script>\n      ';
	});
	
	var indexHTML = fs.readFileSync(debugDir+'/index.html', "utf8");
	indexHTML = indexHTML.replace("@javascript@", scripts);
	fs.writeFile(debugDir+'/index.html', indexHTML, function(err) {
	    if(err) {
	        console.log("error writing to index template: "+err);
	    }
	});
	console.log("updated "+debugDir+"/index.html");
}
var watch = require('nodewatch');
watch.add("../src/js/list.txt").onChange(function(file,prev,curr){
    console.log("javascript list changed, updating debug index.html");
	updateDebugIndexFile();
});
updateDebugIndexFile();