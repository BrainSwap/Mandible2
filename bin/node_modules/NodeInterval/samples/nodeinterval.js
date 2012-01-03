var args, NodeInterval, ni;
args = process.argv.splice(2);
NodeInterval = require('NodeInterval');

ni = new NodeInterval.Watcher({
    watchFolder: '../src/templates/',
    inputFile: '../src/html/index.html',
    replacementString: '@templates@',
    outputFile: '../assets/index.html'
})

// Pass "--watch" from command line to keep the proccess going.
if (args[0] == '--watch'){
   ni.startWatch();
}

// Example of multiple input and output files */
/*
ni = new Nodeinterval.Watcher({
    watchFolder: '../src/templates/',
    inputFile: ['../src/index.html', '../src/index_uncompressed.html'],
    replacementString: '@templates@',
    outputFile: ['../assets/index.html', '../assets/index_uncompressed.html']
}).startWatch();
*/