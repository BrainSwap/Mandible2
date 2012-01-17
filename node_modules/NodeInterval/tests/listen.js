var watchFolder =  'src/templates/',
inputFile =  'src/index.html',
replacementString = '@templates@',
outputFile =  'assets/index.html';

// Create a NI instance.
ni = new NodeInterval.Watcher({
    watchFolder: watchFolder,
    inputFile: inputFile,
    outputFile: outputFile
}).startWatch();
