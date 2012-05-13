var fs = require('fs'),
path = require('path'),
    jsp = require('./node_modules/uglify-js').parser,
    pro = require('./node_modules/uglify-js').uglify,
NodeWatch = require('./node_modules/nodewatch'),
WatchTree = require('./node_modules/watch-tree'),
    knox = require('knox'),
exec = require('child_process').exec,
util = require('util'),
    ISWIN = !!process.platform.match(/^win/);

// Increase limit of EventImitters
// http://stackoverflow.com/questions/8313628/node-js-request-how-to-emitter-setmaxlisteners
NodeWatch.setMaxListeners(0);

/************************ TO MODIFY ************************/

var APP_NAMESPACE = 'website',
    APP_DOMAIN = 'beta.website.com',
    APP_QA_DOMAIN = 'qa.website.net',
    APP_STAGING_DOMAIN = 'staging.website.net';

// Deploy variables
var PROD_SERVER_USER = 'deploy',
    PROD_SERVER_IP = '255.255.255.255',
    PROD_DEPLOY_SCRIPT = 'deploy-prod.sh',
    QA_SERVER_USER = 'deploy',
    QA_SERVER_IP = '255.255.255.255',
    QA_DEPLOY_SCRIPT = 'deploy-qa.sh',
    STAGING_SERVER_USER = 'deploy',
    STAGING_SERVER_IP = '255.255.255.255',
    STAGING_DEPLOY_SCRIPT = 'deploy-staging.sh';

// Amazon S3 Variables
var S3_KEY = '',
    S3_SECRET = '',
    S3_MEDIA_FOLDERS = [ // Used in deciding what goes to S3
        '/js/',
        '/css/',
        '/images/',
        '/polyfill/'
        // '/webfonts/' // Host web fonts locally as they won't work in FF.
    ],
    S3_PROD_BUCKET = 'https://pr-website.s3.amazonaws.com',
    S3_QA_BUCKET = 'https://qa-website.s3.amazonaws.com',
    S3_STAGING_BUCKET = 'https://st-website.s3.amazonaws.com';

/************************ NOT TO MODIFY ************************/

// Development folder paths
var PROD_FOLDER = 'deploy-prod',
    DEBUG_FOLDER = 'deploy-debug';

// JavaScript variables
var JS_FILES = [], // JS file paths parsed from src/index.html between @js concat start@ and @js concat end@)
    JS_START_MARKER = '@javascript concat start@',
    JS_END_MARKER = '@javascript concat end@';

// CSS Variables
var CSS_FILES = [], // parsed from src/index.html between @css concat start@ and @css concat end@
    TEMPLATES_DIRTY = true,
    CONCATED_TEMPLATES,
    CSS_START_MARKER = '@css concat start@',
    CSS_END_MARKER = '@css concat end@';

/********************/
/* Utiliy functions */
/********************/
// Shortcut to run exec command with logging and error support
function execLog(stringCommand, callback){
    exec(stringCommand, function(error, stdout, stderr){
        if (callback){
            callback();
        }

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
}

function getDate(){
    var today = new Date();
    var DD = today.getDate();
    var MM = today.getMonth() + 1; //January is 0!
    var YYYY = today.getFullYear();
    var hh = today.getHours();
    var mm = today.getMinutes();
    var ss = today.getSeconds();

    if (DD<10){DD ='0' + DD}
    if (MM<10){MM = '0' + MM}

    return [MM,DD,YYYY,hh,mm,ss].join('_');
}

function gzipFile(file){
    execLog('gzip ' + file, function(){
        fs.renameSync(file + '.gz', file);
    });
}

/* Called by css:<env> to compress css */
function compressCSS(domain){
    //combine all css into a single scss index file
    parseCSSFileList();

    var allCSSText = '';
    for (i = 0, len = CSS_FILES.length; i < len; i++){
        allCSSText += fs.readFileSync('src/' + CSS_FILES[i], 'utf8');
    }

    allCSSText = namespaceWebfonts(domain, allCSSText);
    fs.writeFileSync(PROD_FOLDER + '/css/index.scss', allCSSText, 'utf8');

    execLog('sass --style=compressed --load-path src/css/ --scss ' + PROD_FOLDER + '/css/index.scss ' + PROD_FOLDER + '/css/index.css');
    //todo: remove the temporary index.scss file in the prod folder. Can't just remove with unlinkSync as sass call is asynch
    //fs.unlinkSync(PROD_FOLDER+'/css/index.scss');
}

function namespaceWebfonts(domain, text){
    return text.replace(/\/webfonts\//g, 'http://' + domain + '/webfonts/');
}

function uploadMediaFoldersToS3(bucket){
    console.log('Uploading media folders to %s...', bucket);
    var bucketDomain = bucket.match(/\/\/(.*)\.s3/)[1];
    S3_MEDIA_FOLDERS.forEach(function(folder){
        uploadFolderToS3(bucketDomain, PROD_FOLDER + folder);
    });
}

function uploadFolderToS3(bucket, folder){
    if (!bucket){
        bucket = '';
    }
    if (!global.knoxClient){
        knoxClient = knox.createClient({
            key: S3_KEY,
            secret: S3_SECRET,
            bucket: bucket
        });
    }

    var uploadFile = function(from){
        var ext = from.match(/\w*$/)[0];
        var contentType;
        var to = '/' + from.replace(PROD_FOLDER + '/', '');
        var meta = {
            'Cache-Control': 'max-age=1209600' // 2 weeks
        }
        console.log('->', from, to);

        switch(ext){
        case 'jpg':
            contentType = 'image/jpeg';
            break;
        case 'png':
            contentType = 'image/png';
            break;
        case 'gif':
            contentType = 'image/gif';
            break;
        case 'html':
            contentType = 'text/html';
            break;
        case 'txt':
            contentType = 'text/plain';
            break;
        case 'mobileprovision':
            contentType = 'application/octet-stream';
            break;
        case 'ipa':
            contentType = 'application/octet-stream';
            break;
        case 'htc':
            contentType = 'text/x-component';
            break;
        case 'css':
            gzipFile(from);
            contentType = 'text/css';
            break;
        case 'js':
            gzipFile(from);
            contentType = 'application/javascript; charset=utf-8';
            break;
        case 'mobileprovision':
            contentType = 'application/xml';
            break;
        case 'ttf':
            gzipFile(from);
            contentType = 'application/x-font-ttf';
            break;
        case 'otf':
            gzipFile(from);
            contentType = 'font/opentype';
            break;
        case 'woff':
            contentType = 'application/x-font-woff';
            break;
        case 'svg':
            contentType = 'image/svg+xml';
            break;
        case 'eot':
            gzipFile(from);
            contentType = 'application/vnd.ms-fontobject';
            break;
        default:
            contentType = 'uknown';
        }

        // Note: Setting small timeout here as gziping files happens with exec
        // which is a child process so we must make sure we wait long enough.
        setTimeout(function(){
            fs.readFile(from, function(err, buf){
                meta['Content-Length'] = buf.length;
                meta['Content-Type'] = contentType;

                if (ext == 'js' || ext == 'css' || ext == 'ttf' || ext == 'otf'  || ext == 'eot'){
                    meta['Content-Encoding'] = 'gzip';
                }

                var req = knoxClient.put(to, meta);
                req.on('response', function(res){
                    if (200 == res.statusCode) {
                        console.log('saved to %s', req.url);
                    }else{
                        console.error('ERROR %s %s:', from, res.statusCode);
                    }
                });
                req.end(buf);
            });
        },500);
    }

	var files = listFilesRecursive(folder);
	files.forEach(function(file){
        uploadFile(file);
    });
}

function parseJavascriptFileList(){
    //generate css list
	var templateText = /@javascript concat start@([\s\S]*?)@javascript concat end@/.exec( fs.readFileSync('src/index.html', 'utf8') )[1];
	//parse out comments to catch any tags that are commented out
	templateText = templateText.replace(/<!--([\s\S]*?)-->/g, '');
	JS_FILES = [];
	var matches = templateText.match(/src="([\s\S]*?)"/g);
	for (var i = 0; i<matches.length; i++){
	    //ugly but works for now since i can't easily get the capture group
	    JS_FILES.push(matches[i].split('"')[1]);
	}
}
function parseCSSFileList(){
    //generate css list
	var templateText = /@css concat start@([\s\S]*?)@css concat end@/.exec( fs.readFileSync('src/index.html', 'utf8') )[1];
	//parse out comments to catch any tags that are commented out
	templateText = templateText.replace(/<!--([\s\S]*?)-->/g, '');
	CSS_FILES = [];
	var matches = templateText.match(/href="([\s\S]*?)"/g);
	for (var i = 0; i<matches.length; i++){
	    //ugly but works for now since i can't easily get the capture group
	    CSS_FILES.push(matches[i].split('"')[1]);
	}
}
function generateConcatedTemplates(){
	CONCATED_TEMPLATES = ''
	var files = listFilesRecursive('src/templates/');
	files.forEach(function(file){
		if (file.indexOf('.tmpl')!=-1){
			CONCATED_TEMPLATES += fs.readFileSync(file, 'utf8') + '\n     ';
		}
    });
}

/* convert and copy all scss and css from src to dev */
function convertAndCopyCSSDev(path){
	var filename = path.split('src/css/').join('').split('.scss').join('.css');

	if (path.indexOf('.css')!=-1){
		console.log('copy: ' + path + ' to dev /css/' + filename);
		exec('cp ' + path + ' ' + DEBUG_FOLDER + '/css/' + filename, function(error, stdout, stderr){
			util.puts(stdout);
		});
	} else {
	    console.log('path: ' + path + ' filename: ' + filename);
	    //special case for font pathing in main _base.css file
        if (filename=='_base.css'){
    	    var cssText = fs.readFileSync(path, 'utf8');
    	    console.log('cssText: ' + cssText);
    	    path = DEBUG_FOLDER + '/css/' + filename.split('.css').join('.scss');
            cssText = cssText.split('@cdnhost@').join('');
            fs.writeFileSync(path, cssText)
    	}
    	exec('sass --style=expanded --load-path src/css/ --update ' + path + ':' + DEBUG_FOLDER + '/css/' + filename, function(error, stdout, stderr){
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
    // path.existsSync is now fs.existsSync in v0.7.6-pre so we must check for it.
    if (!path.existsSync(dir)){
        console.log(dir + ' folder doesn\'t exist. Creating...');
        fs.mkdirSync(dir);
        if (callback){
            callback(dir);
        }
    }
}

/* Copy a file synchronously to a destination file.*/
function copyFileSync(srcFile, destFile) {
    srcFile = platformProofPath(srcFile);
    destFile = platformProofPath(destFile);
	var BUF_LENGTH, buff, bytesRead, fdr, fdw, pos;
	BUF_LENGTH = 64 * 1024;
	buff = new Buffer(BUF_LENGTH);
	fdr = fs.openSync(srcFile, 'r');
	var lastChar = destFile.charAt(destFile.length-1);
	var slashType = ISWIN ? '\\' : '/';
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
    if (!ISWIN){
        //weird on mac the symlinks need this or won't work
        src = '../' + src;
    }
    console.log('creating sym link src: ' + src + ' dest: ' + dest);
    fs.symlinkSync(src, dest, 'dir');
}

/* correct the slashes in paths for alternate platforms */
function platformProofPath(path){
    if (ISWIN){
        path = path.split('/').join('\\');
    } else {
        path = path.split('\\').join('/');
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
	copyFileSync('src/index.html', DEBUG_FOLDER + '/index.html');
	if (TEMPLATES_DIRTY){
		generateConcatedTemplates(true);
	}
	var indexHTML = fs.readFileSync(DEBUG_FOLDER + '/index.html', 'utf8');
	indexHTML = indexHTML.replace(JS_START_MARKER, '')
        .replace(JS_END_MARKER, '')
        .replace(CSS_START_MARKER, '')
        .replace(CSS_END_MARKER, '')
        .split('scss"').join('css"')
        .replace('@templates@', CONCATED_TEMPLATES)
        .split('@cdnhost@').join('');
	fs.writeFile(DEBUG_FOLDER + '/index.html', indexHTML, function(err) {
	    if(err) {
	        console.log('error writing to index template: ' + err);
	    }
	});
	console.log('    updated dev index.html');
}

// Builds prod index file by adding in compressed js, css, and templates.
function updateProdIndexFile(){
    console.log('building production index.html');
    copyFileSync('src/index.html', PROD_FOLDER + '/index.html');
    var indexHTML = fs.readFileSync(PROD_FOLDER + '/index.html', 'utf8')
        .replace(/@javascript concat start@([\s\S]*?)@javascript concat end@/, '<script src="js/index.js"></script>')
        .replace(/@css concat start@([\s\S]*?)@css concat end@/, '<link rel="stylesheet" href="css/index.css" />')
        .replace('@templates@', CONCATED_TEMPLATES);
    var writeErr = fs.writeFileSync(PROD_FOLDER + '/index.html', indexHTML);
	if (writeErr){
	    console.log('error writing to index template: ' + writeErr);
	    }
}


function versionFilesToBucket(bucket){
    var date = getDate();
    var indexHTML = fs.readFileSync(PROD_FOLDER + '/index.html', 'utf8');

    var cssText = fs.readFileSync(PROD_FOLDER + '/css/index.css', 'utf8');
    cssText = cssText.split('@cdnhost@').join(bucket);
    fs.writeFileSync(PROD_FOLDER + '/css/index.css', cssText)

    // Add date timestamp to prod index.css and js.
    fs.renameSync(PROD_FOLDER + '/js/index.js', PROD_FOLDER + '/js/index.' + date + '.js');
    fs.renameSync(PROD_FOLDER + '/css/index.css', PROD_FOLDER + '/css/index.' + date + '.css');

    // Update prod/index.html with the new renamed files.
    indexHTML = indexHTML.replace('js/index.js', bucket + '/js/index.' + date + '.js')
        .replace('css/index.css', bucket + '/css/index.' + date + '.css')
        .split('@cdnhost@').join(bucket);

    fs.writeFileSync(PROD_FOLDER + '/index.html', indexHTML)
}

// Recurses through a dir and outputs an array of files.
function listFilesRecursive(sourceDir){
    sourceDir = platformProofPath(sourceDir);
    var files = [];
    try {
        var filesToCheck = fs.readdirSync(sourceDir);
        for(var i = 0; i < filesToCheck.length; i++) {
            var filePath = platformProofPath(sourceDir + filesToCheck[i]);
            var currFile = fs.lstatSync(filePath);
            if(currFile.isDirectory()) {
                files = files.concat(listFilesRecursive(filePath+'/'));
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
/*  wrench.copyDirSyncRecursive('directory_to_copy', 'new_directory_location', opts);
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
        var currFile = fs.lstatSync(sourceDir + '/' + files[i]);

        if(currFile.isDirectory()) {
            /*  ...and then recursion this thing right on back. */
            copyDirSyncRecursive(sourceDir + '/' + files[i], newDirLocation + '/' + files[i]);
        } else if(currFile.isSymbolicLink()) {
            var symlinkFull = fs.readlinkSync(sourceDir + '/' + files[i]);
            fs.symlinkSync(symlinkFull, newDirLocation + '/' + files[i]);
        } else {
            /*  At this point, we've hit a file actually worth copying... so copy it on over. */
            var contents = fs.readFileSync(sourceDir + '/' + files[i]);
            fs.writeFileSync(newDirLocation + '/' + files[i], contents);
        }
    }
};

// TODO: Use https://github.com/isaacs/rimraf
//from https://github.com/ryanmcgrath/wrench-js/blob/master/lib/wrench.js
/*  wrench.rmdirSyncRecursive('directory_path', forceDelete, failSilent);
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
        var currFile = fs.lstatSync(path + '/' + files[i]);
        console.log('checking: ' + path + '/' + files[i]);
        if(currFile.isSymbolicLink()) {
            // Unlink symlinks
            fs.unlinkSync(path + '/' + files[i]);
        } else if(currFile.isDirectory()){
            // Recursive function back to the beginning
            console.log('curFile is dir: ' + path + '/' + files[i] + ' sym: ' + currFile.isSymbolicLink());
            rmdirSyncRecursive(path + '/' + files[i]);
        } else {
            // Assume it's a file - perhaps a try/catch belongs here?
            fs.unlinkSync(path + '/' + files[i]);
        }
    }

    /*  Now that we know everything in the sub-tree has been deleted, we can delete the main
        directory. Huzzah for the shopkeep. */
    return fs.rmdirSync(path);
};

/****************************************/
/*     Tasks    */
/****************************************/

desc('This is the default task which starts the dev watch script.');
task('default', ['watch-dev'], function(params) {
    console.log('Done with tasks.');
});

/****************/
/* Build        */
/****************/
namespace('build', function () {
    desc('Does a dev build (but not deploy).');
    task('dev', [], function(params) {
        var cssContent, i;

	    // concat templates into the debug index html file
		updateDebugIndexFile();

        // Build css file list
        parseCSSFileList();
        for (i = 0, len = CSS_FILES.length; i < len; i++){
            convertAndCopyCSSDev('src/' + CSS_FILES[i]);
        }

        complete();
    },{
        async : true
    });

    desc('Does a production build (but not deploy).');
    task('prod', ['install:prod', 'templates:prod', 'css:prod', 'js:prod', 'version:prod'], function(params) {
        console.log('Done with tasks.');
    });

    desc('Does a staging build (but not deploy).');
    task('staging', ['install:prod', 'templates:prod', 'css:staging', 'js:prod', 'version:staging'], function(params) {
        console.log('Done with tasks.');
    });

    desc('Does a qa build (but not deploy).');
    task('qa', ['install:prod', 'templates:prod', 'css:qa', 'js:prod', 'version:qa'], function(params) {
    console.log('Done with tasks.');
});

});

/****************/
/* Clean        */
/****************/
namespace('clean', function () {
desc('Remove prod folder so you can rebuild it.');
    task('prod', [], function(params) {
    console.log('Removing prod folder...');
        removeFolder(PROD_FOLDER);
});

desc('Remove dev folder so you can rebuild it.');
    task('dev', [], function(params) {
    console.log('Removing dev folder...');
    //WARNING with windows node.js (even latest .6.11) fs.lstatSync doesn't properly detect symbolic links on windows
    //only this questionable mention under fs.Stats in official node documentation: stats.isSymbolicLink() (only valid with fs.lstat())
    //this will cause passing a folder like below that has symlinks in it to a recusive delete function to delete the
    //content inside of the symlink folders instead of the symlinks themselves. So for now, on windows, don't delete this folder :/
        if (!ISWIN) removeFolder(DEBUG_FOLDER);
    });
});

/****************/
/* Install      */
/****************/
namespace('install', function () {
    desc('Create /deploy-dev and /deploy-prod folders and set up sym links..');
    task('prod', [], function(params) {
        directoryCheck(PROD_FOLDER, function(dir){
            fs.mkdirSync(PROD_FOLDER + '/js');
            fs.mkdirSync(PROD_FOLDER + '/css');
            console.log('copying static folders');

            [
                ['src/images', '/images'],
                ['src/polyfill', '/polyfill'],
                ['src/webfonts', '/webfonts']
            ].forEach(function(fileAr){
                copyDirSyncRecursive(fileAr[0], PROD_FOLDER + fileAr[1]);
});

            [
                'src/apple-touch-icon-57x57-precomposed.png',
                'src/apple-touch-icon-72x72-precomposed.png',
                'src/apple-touch-icon-114x114-precomposed.png',
                'src/apple-touch-icon-precomposed.png',
                'src/apple-touch-icon.png',
                'src/favicon.ico',
                'src/robots.txt',
            ].forEach(function(file){
                copyFileSync(file, PROD_FOLDER + '/');
            });

    });
        console.log('Created prod folders as needed. Run jake clean:prod for complete rebuild.');
});

desc('Create dev and prod folders and set up sym links..');
    task('dev', [], function(params) {
        directoryCheck(DEBUG_FOLDER, function(dir){

            [
                'src/images',
                'src/js',
                'src/polyfill',
                'src/webfonts',
            ].forEach(function(file){
                createSymLink(file, DEBUG_FOLDER + file.replace('src',''));
            });

            directoryCheck(DEBUG_FOLDER+'/css');

            [
                'src/apple-touch-icon-57x57-precomposed.png',
                'src/apple-touch-icon-72x72-precomposed.png',
                'src/apple-touch-icon-114x114-precomposed.png',
                'src/apple-touch-icon-precomposed.png',
                'src/apple-touch-icon.png',
                'src/favicon.ico',
                'src/robots.txt',
            ].forEach(function(file){
                copyFileSync(file, DEBUG_FOLDER + '/');
            });
        });
        console.log('Created dev folders as needed. Run jake clean:dev for complete rebuild.');
    });
});

/****************/
/* CSS          */
/****************/
namespace('css', function () {
    desc('Compress and prep all CSS into prod /css/index.css');
    task('prod', [], function() {
    console.log('Compressed CSS for prod');
        compressCSS(APP_DOMAIN);
    });

    task('staging', [], function() {
        console.log('Compressed CSS for staging');
        compressCSS(APP_STAGING_DOMAIN);
    });

    task('qa', [], function() {
        console.log('Compressed CSS for qa');
        compressCSS(APP_QA_DOMAIN);
    });
});

/****************/
/* JS           */
/****************/
namespace('js', function () {
    desc('Compress all JS prod');
    task('prod', [], function(params) {
        console.log('Compressing JS for prod');
        var concatFiles = concatJS();
        //remove console references
        concatFiles = concatFiles.replace(/console.(log|debug|info|warn|error|assert)(.apply)?\(.*\);?/g, '');
        var uglifyFiles = uglifyJS(concatFiles);
        fs.writeFileSync(PROD_FOLDER + '/js/index.js', uglifyFiles, 'utf8');
    });
});

/****************/
/* Templates    */
/****************/
namespace('templates', function () {
    desc('Concat templates into HTML files into prod index.html');
    task('prod', [], function(params) {
        console.log('Concating Templates for prod');
        generateConcatedTemplates();
        updateProdIndexFile();
    });
});

/****************/
/* Versioning   */
/****************/
namespace('version', function () {
    desc('Version timestamp CSS and JS filename for qa, and update html references.');
    task('qa', [], function() {
        versionFilesToBucket(S3_QA_BUCKET);
    });

    desc('Version timestamp CSS and JS filename for staging, and update html references.');
    task('staging', [], function() {
        versionFilesToBucket(S3_STAGING_BUCKET);
	});

    desc('Version timestamp CSS and JS filename for prod, and update html references.');
    task('prod', [], function() {
        versionFilesToBucket(S3_PROD_BUCKET);
	});
	});

/****************/
/* deploy       */
/****************/
namespace('deploy', function () {
    // Runs jake clean:env build:env s3:env on remote server

    desc('Update Staging env to latest codebase in master');
    task('staging', [], function(params) {
        console.log('Deploying to ' + APP_STAGING_DOMAIN + '...');
        execLog("ssh " + STAGING_SERVER_USER + "@" + STAGING_SERVER_IP +  " './bin/" + STAGING_DEPLOY_SCRIPT + "'");
	});

    desc('Update QA env to latest codebase in master');
    task('qa', [], function(params) {
        console.log('Deploying to ' + APP_QA_DOMAIN + '...');
        execLog("ssh " + QA_SERVER_USER + "@" + QA_SERVER_IP +  " './bin/" + QA_DEPLOY_SCRIPT + "'");
    });

    desc('Update QA env to latest codebase in stable');
    task('qa-stable', [], function(params) {
        console.log('Deploying stable to ' + APP_QA_DOMAIN + '...');
        execLog("ssh " + QA_SERVER_USER + "@" + QA_SERVER_IP +  " './bin/deploy-qa-from-stable.sh'");
	});

    desc('Update prod env to latest codebase in master');
    task('prod', [], function(params) {
        console.log('Deploying to ' + APP_DOMAIN + '...');
        execLog("ssh " + PROD_SERVER_USER + "@" + PROD_SERVER_IP +  " './bin/" + PROD_DEPLOY_SCRIPT + "'");
    });

    desc('Update prod env to latest codebase in stable');
    task('prod-stable', [], function(params) {
        console.log('Deploying stable to ' + APP_DOMAIN + '...');
        execLog("ssh " + PROD_SERVER_USER + "@" + PROD_SERVER_IP +  " './bin/deploy-prod-from-stable.sh'");
	});
});

/****************/
/* S3           */
/****************/
namespace('s3', function () {
    desc('Upload QA assets to Amazon S3.');
    task('qa', [], function(){
        uploadMediaFoldersToS3(S3_QA_BUCKET);
    });

    desc('Upload Staging assets to Amazon S3.');
    task('staging', [], function(){
        uploadMediaFoldersToS3(S3_STAGING_BUCKET);
    });

    desc('Upload Prod assets to Amazon S3.');
    task('prod', [], function(){
        uploadMediaFoldersToS3(S3_PROD_BUCKET);
    });
});

/****************/
/* tests        */
/****************/
namespace('tests', function () {
    task('api', [], function(){
        console.log('running api tests...');
        exec('cd spec && jasmine-node --verbose samplespec.js', function(error, stdout, stderr){
            if (stdout){
                console.log(stdout);
                complete();
            }
            if (stderr){
                console.log('stderr: ' + stderr);
            }
            if (error !== null) {
                console.log('exec error: ' + error);
            }
        });
    },{
        async : true
    });
});

desc('Watch /src css, templates, and index.html for changes and update dev folder');
task('watch-dev', ['clean:dev', 'install:dev'], function(params) {
    console.log('Watching source files for changes to copy to dev');

    var FILE_STATES = ['fileDeleted', 'fileCreated', 'fileModified'];

    // Watch src index template for changes
	NodeWatch.add('src/index.html').onChange(function(file,prev,curr){
	    console.log('src index.html template changed, updating dev folder');
		updateDebugIndexFile();
	});

	// Watch root icons for changes
    [
        'src/apple-touch-icon-57x57-precomposed.png',
        'src/apple-touch-icon-114x114-precomposed.png',
        'src/apple-touch-icon-114x114-precomposed.png',
        'src/apple-touch-icon-precomposed.png',
        'src/apple-touch-icon.png',
        'src/favicon.ico',
        'src/robots.txt',
    ].forEach(function(file){
        NodeWatch.add(file).onChange(function(file,prev,curr){
	        copyFileSync(file, DEBUG_FOLDER + '/');
	    });
    })

	// Watch changes to the templates folder and concat them into the debug index html file
	var templateFolderWatcher = WatchTree.watchTree('src/templates', {
        'sample-rate' : 50,
        match : '\.tmpl$'
    });

    FILE_STATES.forEach(function(status){
	    templateFolderWatcher.on(status, function(path) {
	        console.log('template ' + status + ': ' +  path + '!');
		    TEMPLATES_DIRTY = true;
		updateDebugIndexFile();
	});
    })

	// Watch for changes to the /src/css directory, convert all css files over to dev css folder
	//TODO: verify sub folders are being synced correctly
	var scssFolderWatcher = WatchTree.watchTree('src/css', {
        'sample-rate' : 50,
        match: '\.(css|scss)$'
		});

    FILE_STATES.concat('filePreexisted').forEach(function(status){
        if (status == 'fileDeleted'){
            // Also delete item from debug folder
	        scssFolderWatcher.on(status, function(path) {
	            console.log('    ' + status + ' ' + path + '!');
		        var filename = path.split('src/css/').join('').split('.scss').join('.css');
		        exec('rm ' + DEBUG_FOLDER + '/css/' + filename, function(error, stdout, stderr){
                    console.log('   removed from debug folder!');
			        util.puts(stdout);
	});
	});
        }else{
	        scssFolderWatcher.on(status, function(path) {
	            console.log(status + ' ' + path + '!');
		convertAndCopyCSSDev(path);
	});
        }
	});

	updateDebugIndexFile();
});

desc('Run all unit tests.');
task('test', ['tests:api'], function(){
    console.log('Finished tests.');
});

desc('Get date.');
task('getDate', [], function(){
    console.log(getDate());
});