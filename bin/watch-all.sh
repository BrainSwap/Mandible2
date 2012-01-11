#!/usr/bin/env node
/*
this script monitors src javascript, css, and templates for changes and applies them to /deploy-debug/
*/
var debugDir = "../deploy-debug";

var util = require('util')
var exec = require('child_process').exec;

//delete the current bin-deploy folder to start fresh
exec("rm -r ../deploy-debug", function(error, stdout, stderr){
	util.puts(stdout);
});

var fs = require('fs');
var watch = require('nodewatch');
var WatchTree = require('watch-tree');
var jsListDirty = true;
var jsListText;
var cssListDirty = true;
var cssListText;
var templatesDirty = true;
var concatedTemplates;

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
function generateJavascriptFileList(){
	var jsListPath = "../src/js/list.txt";
	var jsList = fs.readFileSync(jsListPath, "utf8");
	jsListText = "";
	jsList.split(/\r?\n/).forEach(function (line) {
		jsListText+='<script src="js/'+line+'"></script>\n      ';
	});
	jsListDirty = false;
}
function generateCSSFileList(){
	var cssListPath = "../src/scss/list.txt";
	var cssList = fs.readFileSync(cssListPath, "utf8");
	cssListText = "";
	cssList.split(/\r?\n/).forEach(function (line) {
		cssListText+='<link rel="stylesheet" href="css/'+line.split(".scss").join(".css")+'"/>\n        ';
	});
	cssListDirty = false;
}
function generateConcatedTemplates(){
	concatedTemplates = ""
	var files = fs.readdirSync('../src/templates/');
	files.forEach(function(file){
		if (file.indexOf(".tmpl")!=-1){
			concatedTemplates+=fs.readFileSync('../src/templates/'+file, "utf8")+"\n     ";
		}
    });
}

var delayedUpdateInt = NaN;
function updateDebugIndexFile(now){
	if (!now && isNaN(delayedUpdateInt)){
		delayedUpdateInt = setTimeout(function(){
			delayedUpdateInt = NaN;
			updateDebugIndexFile(true);
		}, 50);
		return;
	}
	copyFilesSync('../src/index.html', debugDir+'/index.html');

	if (jsListDirty){
		generateJavascriptFileList();
	}
	if (cssListDirty){
		generateCSSFileList();
	}
	if (templatesDirty){
		generateConcatedTemplates();
	}
	
	var indexHTML = fs.readFileSync(debugDir+'/index.html', "utf8");
	indexHTML = indexHTML.replace("@javascript@", jsListText);
	indexHTML = indexHTML.replace("@css@", cssListText);
	indexHTML = indexHTML.replace("@templates@", concatedTemplates);
	fs.writeFile(debugDir+'/index.html', indexHTML, function(err) {
	    if(err) {
	        console.log("error writing to index template: "+err);
	    }
	});
	console.log("updated "+debugDir+"/index.html");
}

function convertAndCopyCSS(path){
	var filename = path.split("../src/scss/").join("").split(".scss").join(".css");
	if (path.indexOf(".css")!=-1){
		console.log("copy: "+path+" to ../deploy-debug/css/"+filename);
		exec("cp "+path+" ../deploy-debug/css/"+filename, function(error, stdout, stderr){
			util.puts(stdout);
		});
	} else {
		exec("sass --style=expanded --update "+path+":../deploy-debug/css/"+filename, function(error, stdout, stderr){
			util.puts(stdout);
		});
	}
}

//create default dev folder and sym links
exec("./create-folders.sh", function(error, stdout, stderr){
	util.puts(stdout);
	
	//watch changes to javascript list file
	watch.add("../src/js/list.txt").onChange(function(file,prev,curr){
	    console.log("javascript list changed");
	    jsListDirty = true;
		updateDebugIndexFile();
	});

	//watch changes to css list file
	watch.add("../src/scss/list.txt").onChange(function(file,prev,curr){
	    console.log("css list changed");
	    cssListDirty = true;
		updateDebugIndexFile();
	});
	
	//watch changes to the templates folder and concat them into the debug index html file
	var templateFolderWatcher = WatchTree.watchTree("../src/templates", {'sample-rate': 50, match:'\.tmpl$'});
	templateFolderWatcher.on('fileDeleted', function(path) {
	    console.log("deleted template " + path + "!");
		templatesDirty = true;
		updateDebugIndexFile();
	
	});
	templateFolderWatcher.on('fileCreated', function(path) {
	    console.log("created template " + path + "!");
		templatesDirty = true;
		updateDebugIndexFile();
	});
	templateFolderWatcher.on('fileModified', function(path) {
	    console.log("modified template " + path + "!");
		templatesDirty = true;
		updateDebugIndexFile();
	});

	//watch for changes to the /src/scss directory, convert all css files over to /deploy-debug/css
	//TODO: verify sub folders are being synced correctly
	var scssFolderWatcher = WatchTree.watchTree("../src/scss", {'sample-rate': 50, match:'\.(css|scss)$'});
	scssFolderWatcher.on('fileDeleted', function(path) {
	    console.log("deleted " + path + "!");
		var filename = path.split("../src/scss/").join("").split(".scss").join(".css");
		exec("rm ../deploy-debug/css/"+filename, function(error, stdout, stderr){
			util.puts(stdout);
		});
	});
	scssFolderWatcher.on('fileCreated', function(path) {
	    console.log("created " + path + "!");
		convertAndCopyCSS(path);
	});
	scssFolderWatcher.on('fileModified', function(path) {
	    console.log("modified " + path + "!");
		convertAndCopyCSS(path);
	});
	scssFolderWatcher.on('filePreexisted', function(path) {
	    //console.log("filePreexisted " + path + "!");
		convertAndCopyCSS(path);
	});
	
	//monitor template changes and merge them into the index file

	updateDebugIndexFile();
});