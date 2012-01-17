// Test engine.
var vows = require('vows'),
assert = require('assert'),
watch = require('nodewatch'),
fs = require('fs');

// Test package.
var NodeInterval = require('nodeinterval');

// NodeInterval init commands.
var watchFolder =  'src/templates/',
inputFile =  'src/index.html',
replacementString = '@templates@',
outputFile =  'assets/index.html';

// Test variables:
var randomString = 'Hi there id="bob"  ' +(+ new Date),
testFile1 = watchFolder + 'template01.tmpl',
testFile2 = watchFolder + 'dir_level_2/dir_level_3/template09.tmpl';


function fileExists(path){
    try{
        fs.lstatSync(outputFile);
    }catch(e){
        return false;
    }
    return true;
}

function init(){
    // Delete outputFile to start clean tests.
    if (fileExists(outputFile)){
        fs.unlinkSync(outputFile);
    }

    // Create a NI instance.
    ni = new NodeInterval.Watcher({
        watchFolder: watchFolder,
        inputFile: inputFile,
        outputFile: outputFile
    }).startWatch();

    vows.describe('All tests').addBatch({
        'Verifying new ni object': {
            topic: function(){
                return ni;
            },
            'Assert that we are listening to all files, in all sub dirs, and ignoring .dot files..': function(topic){
                assert.length(topic.watchFiles, 10);
            },
            'Assert that passed options are stored in ni.options': function(topic){
                assert.isObject(topic.options);
            },
            'Assert that default options extend passed in options': function(topic){
                assert.equal(topic.options.replacementString, '@templates@');
            }
        },

        'Output file has content': {
            topic: function(){
                if (fileExists(outputFile)){
                    return fs.readFileSync(outputFile, 'utf8');
                }
                return false;
            },
            'Assert output file is updated on start and created if doesn\'t exist.': function(topic){
                assert.isTrue(topic.length > 0);
            }
        },

        'Editing a file': {
            topic: function(){
                var that = this;
                console.log('making file edit...');
                fs.writeFileSync(watchFolder + 'template01.tmpl', randomString, 'utf8');
                // Wait a few secs and check that ni updated the file.
                setTimeout(function(){
                    that.callback();
                } ,8000);
            },
            'Assert concatinated output file has new changes.': function(topic){
                console.log('checking change...');
                var topic = fs.readFileSync(outputFile, 'utf8')
                assert.isTrue(!!topic.match(randomString));

                // Revert change
                console.log('Tests done. Reverting changes...');
                fs.writeFileSync(watchFolder + 'template01.tmpl', '<script type="text/template" id="template-01">\n\tThis is my template 01.\n</script>', 'utf8');
                ni.stopWatch();
            }
        }
    }).run();
}

console.log('Starting test...');
init();