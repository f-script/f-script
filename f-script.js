#!/usr/bin/env node

var path = require('path');
var fs = require('fs');
var shell = require('shelljs');
var program = require('commander');

var packageInfo = require('./package.json');
var compiler = require(path.join(__dirname, './compiler/compiler.js'));
var templatePath = path.resolve(path.join(__dirname, "./compiler/templates"));
var compiled = {};

function getJsName(filename) {
    return path.join(path.dirname(filename), path.basename(filename, path.extname(filename))) + '.js';
}

function compile(filename, debug) {
    var file = fs.readFileSync(filename, 'utf8');
    var base = path.basename(filename, path.extname(filename));
    var dir = path.dirname(filename);
    var fscript = compiler.compile(file, base, templatePath, debug);
    fs.writeFileSync(path.join(dir, base + '.js'), fscript.target);
    for (var i = 0; i < fscript.related.length; i++) {
        if (!compiled[fscript.related[i]]) {
            compile(path.resolve(path.join(dir, fscript.related[i])));
            compiled[fscript.related[i]] = true;
        }
    }
    return fscript;
}

function run(entryPoint) {
    shell.exec("node " + getJsName(entryPoint));
}


//handle args
program
    .version(packageInfo.version)
    .usage('[options] <file ...>')
    .option('-b, --build', 'Build only')
    .option('-r, --run', 'Run last successful build')
    .option('-d, --debug', 'Debug mode')
    .parse(process.argv);
var entryPoint = path.resolve(program.args[0]);
try {
    var res;
    if (!program.build && !program.run) {
        program.build = true;
        program.run = true;
    }
    if (program.build) {
        res = compile(entryPoint, program.debug);
    }
    if (program.run) {
        if (!res) {
            //to-do gethering the package information
            run(entryPoint);
        } else if (res.package == 'umd' || res.package == 'cmd') {
            run(entryPoint);
        } else {
            console.log('Can only run the package defined by umd or commonjs standard');
        }
    }
} catch (e) {
    console.log(e);
}