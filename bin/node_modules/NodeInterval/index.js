var fs = require('fs'),
  _ = require('underscore'),
  watch = require('nodewatch'),
  log = require('simple-logger');

(function(NodeInterval){
    NodeInterval.Watcher = function(options){
        var that = this;
        this.options = _.extend(this.defaults, options);
        _(this).extend(this.options);

        this.watchFiles = [];

        // TODO: We should store the current set of files in an array for future
        // comparing.
        _.each(this.getFilesFrom(this.watchFolder), function(file){
            that.watchFiles.push(file);
        });

        // Also watch the input file for changes.
        // TODO: If inputFile changes, unwatch removed file, or watch new file.
        if (options.inputFile instanceof Array){
            _.each(options.inputFile, function(file){
                that.watchFiles.push(file);
            });
        }else{
            this.watchFiles.push(options.inputFile);
        }

        // Render files on start.
        log.log_level = 'info';
        this.updateIndex();
        return this;
    }

    _.extend(NodeInterval.Watcher.prototype, {
        defaults: {
            watchFolder: '../src/templates/',
            inputFile: '../src/html/index.html',
            replacementString: '@templates@',
            outputFile: '../assets/index.html'
        },

        startWatch: function(){
            var that = this;

            _.each(this.watchFiles, function(file){
                watch.add(file);
            });

            log.info('NodeInterval is watching for changes. Press Ctrl-C to stop.');

            // Start the watch change listener.
            watch.onChange(function(file, prevTime, currTime){
                log.info('>>> Change detected to:', file);
                that.updateIndex();
            });
            return this;
        },

        stopWatch: function(){
            watch.clearListeners();

            _.each(this.watchFiles, function(file){
                watch.remove(file);
            });
            return this;
        },

        // Recursively return an array of all files (paths) in a directory.
        getFilesFrom: function(dir){
            var filesAr = [];
            var recurse;

            // Normalize path.
            if (dir[dir.length-1] !== '/'){
                dir = dir + '/';
            }

            recurse = function(dir){
                var arr = fs.readdirSync(dir);
                if (arr.length){
                    _.each(arr, function(fileOrDir){
                        if (fileOrDir[0] !== '.'){

                            if (fs.lstatSync(dir + fileOrDir).isDirectory()){
                                recurse(dir + fileOrDir + '/');
                            }else{
                                filesAr.push(dir + fileOrDir);
                            }
                        }
                    });
                }
            }
            recurse(dir);
            return filesAr;
        },

        // Get the text contents of a file.
        getFileContents: function(file){
            return fs.readFileSync(file, 'utf8');
        },

        // Concat an array of files together into a single string.
        stringFromFiles: function(filesAr){
            var that = this;
            var str = '';
            _.each(filesAr, function(file){
                str += that.getFileContents(file);
            });
            return str;
        },

        // Write a string to a file.
        writeToFile: function(file, str){
            log.info('overwrite', file);
            fs.writeFileSync(file, str, 'utf8');
        },

        // Update target page with new templates.
        updateIndex: function(){
            var date = new Date();
            // Ar of sorted ids from each template.
            var idsAr = [];
            // Lookup hash of ids to template content.
            var fileHash = {};
            // Final concated text content.
            var content = '';
            var template;
            var f;

            // For each file get its template id so we can sort alphabetically.
            _.each(this.getFilesFrom(this.watchFolder), function(file, i, list){
                var contents = this.getFileContents(file);
                var id = contents.match(/id=['"](.*)['"]/);
                if (id){
                    id = id[1];
                    // Add to filehash
                    fileHash[id] = contents;
                    idsAr.push(id);
                }else{
                    throw new Error('Template missing id: ' +  file);
                }
            }, this);

            idsAr.sort();

            _.each(idsAr, function(id){
                content += fileHash[id];
            });

            if (this.outputFile instanceof Array){
                for (f = 0; f < this.outputFile.length; f++){
                    template = this.getFileContents(this.inputFile[f]);
                    template = template.replace(this.replacementString, content);

                    this.writeToFile(this.outputFile[f], template);
                }
            }else{
                template = this.getFileContents(this.inputFile);
                template = template.replace(this.replacementString, content);

                this.writeToFile(this.outputFile, template);
            }

            log.info('Completed in ' + ((new Date() - date) / 1000) + ' seconds.');
        }
    });

    module.exports = NodeInterval;
})({});