#!/usr/bin/env node
var fs = require('fs'),
args = process.argv.splice(2);

var file = args[0];
var content = fs.readFileSync(file, 'utf8');
content = content.replace(/[\s\t]*console.*/g, '');
fs.writeFileSync(file, content, 'utf8');

