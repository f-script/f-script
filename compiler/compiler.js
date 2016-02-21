var parser = require('./parser/f-script.js');
var path = require('path');
var fs = require('fs');
var ejs = require('ejs');
var modifyMetaHooks={
    'class':handleClassModify,
}
var debugFlag = false;
function getTemplateStr(templatePath,name){
    return fs.readFileSync(path.join(templatePath,name), 'utf-8');
}
//all code templates 
var templateStrs = {}
function handleClassModify(meta,lines){
    if(!meta.metaClass){
        meta.metaClass="null";
    }
    var fbody = "";
    if(meta.classBody){
        fbody = getLines(meta.classBody,lines).join('\n');
        delLines(meta.classBody,lines);
    }
    meta.classBody = fbody;
    if(meta.extendsNames){
        if(meta.extendsNames.length>1){
            throw "Don't support multiple extends now";
        }
        meta.baseClass = meta.extendsNames[0]; // for now only support single extends
        meta.extendsNames = meta.extendsNames.join(',');
    }else{
        meta.extendsNames = "null";
        meta.baseClass = "null";
    }
}

function modifyLines(pos,content,meta,template,lines,packageStd){
    //console.log(arguments);
    var startline = pos.start[0]-1;
    var startColumn = pos.start[1];
    var endline = pos.end[0]-1;
    var endColumn = pos.end[1]-1;
    if(meta){
        modifyMetaHooks[meta.type](meta,lines);
    }
    //use native
    if(template&&packageStd.indexOf('.native')!=-1){
        if(templateSts[template+'.native']){
            template += '.native';
        }
    }
    if(template&&templateStrs[template]){
        content = ejs.render(templateStrs[template],meta);
    }
    //console.log(content);
    delLines(pos,lines);
    if(startline == endline){
        lines[startline] = lines[startline].substring(0,startColumn)+ content + lines[endline].substring(endColumn+1,lines[endline].length);
    }else{
        lines[startline] += content.replace(/"""/g,'"')+lines[endline];
        lines[endline] = "";
    }
    
}
function getLines(pos,lines){
    var startline = pos.start[0]-1;
    var startColumn = pos.start[1];
    var endline = pos.end[0]-1;
    var endColumn = pos.end[1]-1;
    var res = [];
    if(startline!=endline){
        res.push(lines[startline].substring(startColumn,lines[startline].length));
        for(var i = startline +1;i<endline;i++){
            res.push(lines[i]);
        }
        res.push(lines[endline].substring(0,endColumn));
    }else{
        if(startColumn==endColumn) return res;
        res.push(lines[startline].substring(startColumn,endColumn+1));
    }
    return res;
}
function delLines(pos,lines){
    var startline = pos.start[0]-1;
    var startColumn = pos.start[1];
    var endline = pos.end[0]-1;
    var endColumn = pos.end[1]-1;
    var i;
    if(startline!=endline){
        lines[startline]=lines[startline].substring(0,startColumn);
        for(i = startline +1;i<endline;i++){
            lines[i]='';
        }
        lines[endline]=lines[endline].substring(endColumn+1,lines[endline].length);
    }else{
        var empty="";
        for(i = 0;i<endColumn-startColumn;i++){
            empty += " ";
        }
        lines[startline] = lines[startline].substring(0,startColumn)+ empty + lines[endline].substring(endColumn+1,lines[endline].length);
    }
}

function compile(input,fileName,templatePath,debug){
    var i;
    debugFlag = debug;
    //init templates
    templateStrs = {
        'class':getTemplateStr(templatePath,'class'),
        'class.native':getTemplateStr(templatePath,'class.native'),
        'amd':getTemplateStr(templatePath,'amd'),
        'umd':getTemplateStr(templatePath,'umd'),
        'umd.native':getTemplateStr(templatePath,'umd.native'),
        'cmd':getTemplateStr(templatePath,'cmd')
    }
    //jison parser don't support the windows ending
    // may fix this in jison directly
    input=input.replace(/\r\n/g,'\n');
    try{
        var ast = parser.parse(input).fs;
    }catch(e){
        throw e;
    }
    if(debugFlag){
        console.log(JSON.stringify(ast,null,4));
    }
    //init the use statement
    if(!ast.use){
        ast.use = '"umd"';
    }
    ast.use = ast.use.toLowerCase();
    ast.use = ast.use.replace(/"|'/g,"").trim();
    if(ast.use == 'commonjs'){
        ast.use = 'cmd'
    }
    //init the code metrix
    var lines = input.split(/\n|\r/);
    if(ast.delLines){
        for(i=0;i<ast.delLines.length;i++){
            delLines(ast.delLines[i],lines);
        }
    }
    if(ast.modifyLines){
        for(i=0;i<ast.modifyLines.length;i++){
            modifyLines(
                ast.modifyLines[i].pos,
                ast.modifyLines[i].content,
                ast.modifyLines[i].meta,
                ast.modifyLines[i].template,
                lines,ast.use);
        }
    }
    
    //format the lines
    lines = lines.filter(function(val){
        return val!=='';
    });
    if(ast.use.indexOf('cmd')==-1){
        for(i=0;i<lines.length;i++){
            lines[i] = '    '+lines[i];
        }
    }
    
    //prepare the target script
    var output = lines.join('\n');

    //compute packages defs , import and export
    var amdImportNames = "";
    var umdCmdImportNames = "";
    var cmdImportNames = "";
    var refNames ="";
    var browserRef = "";
    var related = [];
    if(ast.import){
        for(i=0;i<ast.import.length;i++){
            var unQuotedImportName = ast.import[i].name.replace(/"|'/g,"").trim();
            if(!ast.import[i].refname){
                ast.import[i].refname = path.basename(unQuotedImportName,path.extname(unQuotedImportName));
            }
            var importExt = path.extname(unQuotedImportName);
            if(importExt == '.fs'){
                related.push(unQuotedImportName);
                ast.import[i].name = ast.import[i].name.replace('.fs','.js');
            }
            amdImportNames += ast.import[i].name;
            umdCmdImportNames += 'require('+ast.import[i].name+')';
            cmdImportNames += 'var '+ast.import[i].refname+'=require('+ast.import[i].name+');';
            refNames += ast.import[i].refname;
            browserRef += 'root.'+ast.import[i].refname;
            if(i<ast.import.length-1){
                amdImportNames += ',';
                umdCmdImportNames += ',';
                refNames += ',';
                browserRef += ',';
            }
        }
    }
    var cmdExports = "{";
    if(ast.export){
        for(i=0;i<ast.export.length;i++){
            cmdExports += ast.export[i].exportName+':'+ast.export[i].orignalName;
            if(i<ast.export.length-1){
                cmdExports += ',';
            }
        };
    }
    cmdExports += "}";

    //handle use statement
    if(!templateStrs[ast.use]){
        throw new Error('Using an unknown package standard');
    }
    output = ejs.render(templateStrs[ast.use],{
        amdImportNames:amdImportNames,
        umdCmdImportNames:umdCmdImportNames,
        cmdImportNames:cmdImportNames,
        fileName:fileName,
        browserRef:browserRef,
        refNames:refNames,
        script:output,
        cmdExports:cmdExports,
    });
    return {target:output,package:ast.use,related:related};
}

module.exports = {compile:compile}