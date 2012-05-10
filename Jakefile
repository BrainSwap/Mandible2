var fs = require('fs'),
path = require('path'),
jsp = require("./node_modules/uglify-js").parser,
pro = require("./node_modules/uglify-js").uglify,
NodeWatch = require('./node_modules/nodewatch'),
WatchTree = require('./node_modules/watch-tree'),
exec = require('child_process').exec,
util = require('util'),
isWin = !!process.platform.match(/^win/);

var prodFolder = "deploy-prod";
var debugFolder = "deploy-debug";

var jsListDirty = true;
//array of JS file paths parsed from src/index.html between @js concat start@ and @js concat end@
var JS_FILES = [];
var jsStartMarker = "@javascript concat start@";
var jsEndMarker = "@javascript concat end@";

var cssListDirty = true;
//array of CSS file paths parsed from src/index.html between @css concat start@ and @css concat end@
var CSS_FILES = [];
var templatesDirty = true;
var concatedTemplates;
var cssStartMarker = "@css concat start@";
var cssEndMarker = "@css concat end@";

/********************/
/* Utiliy functions */
/********************/

function parseJavascriptFileList(){
    //generate css list
	var templateText = /@javascript concat start@([\s\S]*?)@javascript concat end@/.exec( fs.readFileSync("src/index.html", "utf8") )[1];
	//parse out comments to catch any tags that are commented out
	templateText = templateText.replace(/<!--([\s\S]*?)-->/g, "");
	JS_FILES = []; 
	var matches = templateText.match(/src="([\s\S]*?)"/g);
	for (var i = 0; i<matches.length; i++){
	    //ugly but works for now since i can't easily get the capture group
	    JS_FILES.push(matches[i].split("\"")[1]);
	}
}
function parseCSSFileList(){
    //generate css list
	var templateText = /@css concat start@([\s\S]*?)@css concat end@/.exec( fs.readFileSync("src/index.html", "utf8") )[1];
	//parse out comments to catch any tags that are commented out
	templateText = templateText.replace(/<!--([\s\S]*?)-->/g, "");
	CSS_FILES = []; 
	var matches = templateText.match(/href="([\s\S]*?)"/g);
	for (var i = 0; i<matches.length; i++){
	    //ugly but works for now since i can't easily get the capture group
	    CSS_FILES.push(matches[i].split("\"")[1]);
	}
}
function generateConcatedTemplates(){
	concatedTemplates = ""
	var files = listFilesRecursive('src/templates/');
	files.forEach(function(file){
		if (file.indexOf(".tmpl")!=-1){
			concatedTemplates+=fs.readFileSync(file, "utf8")+"\n     ";
		}
    });
}

/* convert and copy all scss and css from src to dev */
function convertAndCopyCSSDev(path){
	var filename = path.split("src/css/").join("").split(".scss").join(".css");
	if (path.indexOf(".css")!=-1){
		console.log("copy: "+path+" to dev /css/"+filename);
		exec("cp "+path+" "+debugFolder+"/css/"+filename, function(error, stdout, stderr){
			util.puts(stdout);
		});
	} else {
		exec("sass --style=expanded --load-path src/css/ --update "+path+":"+debugFolder+"/css/"+filename, function(error, stdout, stderr){
			util.puts(stdout);
		});
	}
}

/* Concats all JS files together as one long string. Adds line breaks between files. */
function concatJS(){
    parseJavascriptFileList();
    var concatFiles = [], i;
    for (i = 0, len = JS_FILES.length; i < len; i++){
        var file = 'src/'+JS_FILES[i];
        concatFiles.push(fs.readFileSync(file, 'utf8'));
    }
    return concatFiles.join('\n');
}

/* Takes a string of JS and returns a compresses version of it. */
function uglifyJS(str){
    // parse code and get the initial AST
    var ast = jsp.parse(str);
    // get a new AST with mangled names
    ast = pro.ast_mangle(ast);
    // get an AST with compression optimizations
    ast = pro.ast_squeeze(ast);
    // compressed code here
    return pro.gen_code(ast);
}
/* Checks if directory exists, creates if needed with optional created callback. */
function directoryCheck(dir, callback){
    dir = platformProofPath(dir);
    if (!path.existsSync(dir)){
        console.log(dir + " folder doesn't exist. Creating...");
        fs.mkdirSync(dir);
        if (callback){
            callback(dir);
        }
    }
}

/* copy a file synchronously to a destination file.*/
function copyFileSync(srcFile, destFile) {
    srcFile = platformProofPath(srcFile);
    destFile = platformProofPath(destFile);
	var BUF_LENGTH, buff, bytesRead, fdr, fdw, pos;
	BUF_LENGTH = 64 * 1024;
	buff = new Buffer(BUF_LENGTH);
	fdr = fs.openSync(srcFile, 'r');
	var lastChar = destFile.charAt(destFile.length-1);
	var slashType = isWin ? "\\" : "/";
	if (lastChar==slashType){
	    var fileName = srcFile.split(slashType);
	    fileName = fileName[fileName.length-1];
	    destFile = destFile+fileName;
	}
	fdw = fs.openSync(destFile, 'w');
	bytesRead = 1;
	pos = 0;
	while (bytesRead > 0) {
	  //WARNING this creates an error on windows on latest node (.6.11), use .6.10 for now https://github.com/joyent/node/issues/2807
	  bytesRead = fs.readSync(fdr, buff, 0, BUF_LENGTH, pos);
	  fs.writeSync(fdw, buff, 0, bytesRead);
	  pos += bytesRead;
	}
	fs.closeSync(fdr);
	return fs.closeSync(fdw);
}

function removeFolder(folder){
    folder = platformProofPath(folder);
    rmdirSyncRecursive(folder, true);
}

/* synchronously create sym link of */
function createSymLink(src, dest){
    src = platformProofPath(src);
    dest = platformProofPath(dest);
    if (!isWin){
        //weird on mac the symlinks need this or won't work
        src = "../"+src;
    }
    console.log("creating sym link src: "+src+" dest: "+dest);
    fs.symlinkSync(src, dest, "dir");
}

/* correct the slashes in paths for alternate platforms */
function platformProofPath(path){
    if (isWin){
        path = path.split("/").join("\\");
    } else {
        path = path.split("\\").join("/");
    }
    return path;
}

var delayedUpdateInt = NaN;
function updateDebugIndexFile(now){
	if (!now && isNaN(delayedUpdateInt)){
	    //prevent recompile from being called too often
		delayedUpdateInt = setTimeout(function(){
			delayedUpdateInt = NaN;
			updateDebugIndexFile(true);
		}, 50);
		return;
	}
	copyFileSync('src/index.html', debugFolder+'/index.html');
	if (templatesDirty){
		generateConcatedTemplates(true);
	}
	var indexHTML = fs.readFileSync(debugFolder+'/index.html', "utf8");
	indexHTML = indexHTML.replace(jsStartMarker, "");
	indexHTML = indexHTML.replace(jsEndMarker, "");
	indexHTML = indexHTML.replace(cssStartMarker, "");
	indexHTML = indexHTML.replace(cssEndMarker, "");
	indexHTML = indexHTML.split("scss\"").join("css\"");
	indexHTML = indexHTML.replace("@templates@", concatedTemplates);
	fs.writeFile(debugFolder+'/index.html', indexHTML, function(err) {
	    if(err) {
	        console.log("error writing to index template: "+err);
	    }
	});
	console.log("updated dev index.html");
}

function updateProdIndexFile(){
    console.log("building production index.html");
    copyFileSync('src/index.html', prodFolder+'/index.html');
    var indexHTML = fs.readFileSync(prodFolder+'/index.html', "utf8");
	indexHTML = indexHTML.replace(/@javascript concat start@([\s\S]*?)@javascript concat end@/, '<script src="js/index.js"></script>');
	indexHTML = indexHTML.replace(/@css concat start@([\s\S]*?)@css concat end@/, '<link rel="stylesheet" href="css/index.css" />');
	indexHTML = indexHTML.replace("@templates@", concatedTemplates);
	fs.writeFile(prodFolder+'/index.html', indexHTML, function(err) {
	    if(err) {
	        console.log("error writing to index template: "+err);
	    }
	});
}

listFilesRecursive = function(sourceDir){
    sourceDir = platformProofPath(sourceDir);
    var files = [];
    try {
        var filesToCheck = fs.readdirSync(sourceDir);
        for(var i = 0; i < filesToCheck.length; i++) {
            var filePath = platformProofPath(sourceDir + filesToCheck[i]);
            var currFile = fs.lstatSync(filePath);
            if(currFile.isDirectory()) {
                files = files.concat(listFilesRecursive(filePath+"/"));
            } else {
                files.push(sourceDir+filesToCheck[i]);
            }
        }
    } catch (err) {
        throw new Error(err.message);
    }
    return files;
}

//from https://github.com/ryanmcgrath/wrench-js/blob/master/lib/wrench.js
/*  wrench.copyDirSyncRecursive("directory_to_copy", "new_directory_location", opts);
 *
 *  Recursively dives through a directory and moves all its files to a new location. This is a
 *  Synchronous function, which blocks things until it's done. If you need/want to do this in
 *  an Asynchronous manner, look at wrench.copyDirRecursively() below.
 *
 *  Note: Directories should be passed to this function without a trailing slash.
 */
copyDirSyncRecursive = function(sourceDir, newDirLocation) {
    sourceDir = platformProofPath(sourceDir);
    newDirLocation = platformProofPath(newDirLocation);
    /*  Create the directory where all our junk is moving to; read the mode of the source directory and mirror it */
    var checkDir = fs.statSync(sourceDir);
    fs.mkdirSync(newDirLocation, checkDir.mode);

    var files = fs.readdirSync(sourceDir);

    for(var i = 0; i < files.length; i++) {
        var currFile = fs.lstatSync(sourceDir + "/" + files[i]);

        if(currFile.isDirectory()) {
            /*  ...and then recursion this thing right on back. */
            copyDirSyncRecursive(sourceDir + "/" + files[i], newDirLocation + "/" + files[i]);
        } else if(currFile.isSymbolicLink()) {
            var symlinkFull = fs.readlinkSync(sourceDir + "/" + files[i]);
            fs.symlinkSync(symlinkFull, newDirLocation + "/" + files[i]);
        } else {
            /*  At this point, we've hit a file actually worth copying... so copy it on over. */
            var contents = fs.readFileSync(sourceDir + "/" + files[i]);
            fs.writeFileSync(newDirLocation + "/" + files[i], contents);
        }
    }
};

//from https://github.com/ryanmcgrath/wrench-js/blob/master/lib/wrench.js
/*  wrench.rmdirSyncRecursive("directory_path", forceDelete, failSilent);
 *
 *  Recursively dives through directories and obliterates everything about it. This is a
 *  Sync-function, which blocks things until it's done. No idea why anybody would want an
 *  Asynchronous version. :\
 */
rmdirSyncRecursive = function(path, failSilent) {
    path = platformProofPath(path);
    var files;

    try {
        files = fs.readdirSync(path);
    } catch (err) {
        if(failSilent) return;
        throw new Error(err.message);
    }

    /*  Loop through and delete everything in the sub-tree after checking it */
    for(var i = 0; i < files.length; i++) {
        var currFile = fs.lstatSync(path + "/" + files[i]);
        console.log("checking: "+path + "/" + files[i]);
        if(currFile.isSymbolicLink()) {
            // Unlink symlinks
            fs.unlinkSync(path + "/" + files[i]);
        } else if(currFile.isDirectory()){
            // Recursive function back to the beginning
            console.log("curFile is dir: "+path + "/" + files[i]+" sym: "+currFile.isSymbolicLink());
            rmdirSyncRecursive(path + "/" + files[i]);
        } else {
            // Assume it's a file - perhaps a try/catch belongs here?
            fs.unlinkSync(path + "/" + files[i]);
        }
    }

    /*  Now that we know everything in the sub-tree has been deleted, we can delete the main
        directory. Huzzah for the shopkeep. */
    return fs.rmdirSync(path);
};

/********************/
/*     Tasks    */
/********************/

desc('This is the default task which starts the dev watch script.');
task('default', ['watch-dev'], function(params) {
    console.log('Done with tasks.');
});

desc('Does a production build.');
task('build-prod', ['install-prod', 'css-prod', 'js-prod', 'templates-prod'], function(params) {
    console.log('Done with tasks.');
});

desc('Remove prod folder so you can rebuild it.');
task('clean-prod', [], function(params) {
    console.log('Removing prod folder...');
    removeFolder(prodFolder);
});

desc('Remove dev folder so you can rebuild it.');
task('clean-dev', [], function(params) {
    console.log('Removing dev folder...');
    //WARNING with windows node.js (even latest .6.11) fs.lstatSync doesn't properly detect symbolic links on windows
    //only this questionable mention under fs.Stats in official node documentation: stats.isSymbolicLink() (only valid with fs.lstat())
    //this will cause passing a folder like below that has symlinks in it to a recusive delete function to delete the 
    //content inside of the symlink folders instead of the symlinks themselves. So for now, on windows, don't delete this folder :/
    if (!isWin) removeFolder(debugFolder);
});


desc('Create prod folders and set up sym links..');
task('install-prod', [], function(params) {
    directoryCheck(prodFolder, function(dir){
        fs.mkdirSync(prodFolder+'/js');
         fs.mkdirSync(prodFolder+'/css');
        console.log("copying static folders");
        copyDirSyncRecursive("src/images", prodFolder+"/images");
        copyDirSyncRecursive("src/polyfill", prodFolder+"/polyfill");
        copyFileSync('src/apple-touch-icon-57x57-precomposed.png', prodFolder+'/');
    	copyFileSync('src/apple-touch-icon-72x72-precomposed.png', prodFolder+'/');
    	copyFileSync('src/apple-touch-icon-114x114-precomposed.png', prodFolder+'/');
    	copyFileSync('src/apple-touch-icon-precomposed.png', prodFolder+'/');
    	copyFileSync('src/apple-touch-icon.png', prodFolder+'/');
    	copyFileSync('src/favicon.ico', prodFolder+'/');
    	copyFileSync('src/robots.txt', prodFolder+'/');
    });
    console.log('Created prod folders as needed. Run jake clean for complete rebuild.');
});

desc('Create dev and prod folders and set up sym links..');
task('install-dev', [], function(params) {
    directoryCheck(debugFolder, function(dir){ 
        createSymLink("src/images", debugFolder+"/images");
        createSymLink("src/js", debugFolder+"/js");
        createSymLink("src/polyfill", debugFolder+"/polyfill");
        directoryCheck(debugFolder+'/css');
        copyFileSync('src/apple-touch-icon-57x57-precomposed.png', debugFolder+'/');
    	copyFileSync('src/apple-touch-icon-72x72-precomposed.png', debugFolder+'/');
    	copyFileSync('src/apple-touch-icon-114x114-precomposed.png', debugFolder+'/');
    	copyFileSync('src/apple-touch-icon-precomposed.png', debugFolder+'/');
    	copyFileSync('src/apple-touch-icon.png', debugFolder+'/');
    	copyFileSync('src/favicon.ico', debugFolder+'/');
    	copyFileSync('src/robots.txt', debugFolder+'/');
    });
    console.log('Created dev folders as needed. Run jake clean for complete rebuild.');
});

desc('Compress all CSS into prod /css/index.css');
task('css-prod', [], function(params) {
    console.log('Compressed CSS for prod');
    //combine all css into a single scss index file
    parseCSSFileList();
    
    var allCSSText = "";
    for (i = 0, len = CSS_FILES.length; i < len; i++){
        allCSSText+=fs.readFileSync("src/"+CSS_FILES[i], "utf8");
    }
    fs.writeFileSync(prodFolder+"/css/index.scss", allCSSText, 'utf8');
    
    var command = "sass --style=compressed --load-path src/css/ --scss "+prodFolder+"/css/index.scss "+prodFolder+"/css/index.css";
    exec(command, function(error, stdout, stderr){
        if (stdout){
            console.log(stdout);
        }
        if (stderr){
            console.log('stderr: ' + stderr);
        }
        if (error !== null) {
            console.log('exec error: ' + error);
        }
    });
    //todo: remove the temporary index.scss file in the prod folder. Can't just remove with unlinkSync as sass call is asynch
    //fs.unlinkSync(prodFolder+"/css/index.scss");
});

desc('Compress all JS prod');
task('js-prod', [], function(params) {
    console.log('Compressing JS for prod');
    var concatFiles = concatJS();
    //remove console references
    concatFiles = concatFiles.replace(/console.(log|debug|info|warn|error|assert)(.apply)?\(.*\);?/g, '');
    var uglifyFiles = uglifyJS(concatFiles);
    fs.writeFileSync(prodFolder+'/js/index.js', uglifyFiles, 'utf8');
});

desc('Concat templates into HTML files into prod index.html');
task('templates-prod', [], function(params) {
    console.log('Concating Templates for prod');
    generateConcatedTemplates();
    updateProdIndexFile();
});

desc('Watch src css, js, templates, and index.html for changes and update dev folder');
task('watch-dev', ['clean-dev', 'install-dev'], function(params) {
    console.log('Watching source files for changes to copy to dev');
    
    //watch src index template for changes
	NodeWatch.add("src/index.html").onChange(function(file,prev,curr){
	    console.log("src index.html template changed, updating dev folder");
		updateDebugIndexFile();
	});
	
	//watch root icons for changes
	NodeWatch.add("src/apple-touch-icon-57x57-precomposed.png").onChange(function(file,prev,curr){
	    copyFileSync(file, debugFolder+'/');
	});
	NodeWatch.add("src/apple-touch-icon-72x72-precomposed.png").onChange(function(file,prev,curr){
	    copyFileSync(file, debugFolder+'/');
	});
	NodeWatch.add("src/apple-touch-icon-114x114-precomposed.png").onChange(function(file,prev,curr){
	    copyFileSync(file, debugFolder+'/');
	});
	NodeWatch.add("src/apple-touch-icon-precomposed.png").onChange(function(file,prev,curr){
	    copyFileSync(file, debugFolder+'/');
	});
	NodeWatch.add("src/apple-touch-icon.png").onChange(function(file,prev,curr){
	    copyFileSync(file, debugFolder+'/');
	});
	NodeWatch.add("src/favicon.ico").onChange(function(file,prev,curr){
	    copyFileSync(file, debugFolder+'/');
	});
	NodeWatch.add("src/robots.txt").onChange(function(file,prev,curr){
	    copyFileSync(file, debugFolder+'/');
	});
	
	//watch changes to the templates folder and concat them into the debug index html file
	var templateFolderWatcher = WatchTree.watchTree("src/templates", {'sample-rate': 50, match:'\.tmpl$'});
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

	//watch for changes to the /src/css directory, convert all css files over to dev css folder
	//TODO: verify sub folders are being synced correctly
	var scssFolderWatcher = WatchTree.watchTree("src/css", {'sample-rate': 50, match:'\.(css|scss)$'});
	scssFolderWatcher.on('fileDeleted', function(path) {
	    console.log("deleted " + path + "!");
		var filename = path.split("src/css/").join("").split(".scss").join(".css");
		exec("rm "+debugFolder+"/css/"+filename, function(error, stdout, stderr){
			util.puts(stdout);
		});
	});
	scssFolderWatcher.on('fileCreated', function(path) {
	    console.log("created " + path + "!");
		convertAndCopyCSSDev(path);
	});
	scssFolderWatcher.on('fileModified', function(path) {
	    console.log("modified " + path + "!");
		convertAndCopyCSSDev(path);
	});
	scssFolderWatcher.on('filePreexisted', function(path) {
	    //console.log("filePreexisted " + path + "!");
		convertAndCopyCSSDev(path);
	});
	updateDebugIndexFile();
});

desc('deploy to staging environment');
task('deploy-staging', [], function(params) {
    console.log('Deploying to staging server');
    var cmd = 'rsync -arz --progress --delete --exclude=".DS_Store" deploy-prod/ HOST:/PATH/';
    exec(cmd, function(error, stdout, stderr){
		util.puts(stdout);
	});
});

desc('deploy to prod environment');
task('deploy-prod', [], function(params) {
    console.log('Deploying to prod server');
});