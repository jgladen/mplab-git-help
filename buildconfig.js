'use strict';

var fs=require('fs');



function usage(){
  console.error("Usage node buildconfig.js [cfgdata file] --default");
  process.exit(2);
}

if(process.argv.length<3){ usage();}

process.argv.shift();
process.argv.shift();

var reDefault = /-d|--default/;

var isDefault=false;

var arg;
var sourceFile;
while(arg=process.argv.shift()){
  if(arg.match(reDefault)){
    isDefault=true;
  }else if(fs.existsSync(arg)){
    if(sourceFile!==undefined){ usage(); }
    sourceFile=arg;
  }else{
    usage();
  }
}

// var configData = fs.readFileSync("C:\\Program Files (x86)\\Microchip\\xc8\\v1.40\\dat\\cfgdata\\18f46k80.cfgdata");
// "C:\\Program Files (x86)\\Microchip\xc8\v1.40\dat\cfgdata\18f46k80.cfgdata"

var configData = fs.readFileSync(sourceFile);

var configDataLines = configData.toString().split(/\r\n|\n/);

var reComment = /^#/;

// CWORD:<address>:<mask>:<default value>[:<name>[,<alias list>]]
var reWord = /CWORD:([0-9a-fA-F]+):([0-9a-fA-F]+):([0-9a-fA-F]+)(?::([_A-Za-z0-9]+)(?:,(.*))?)?/;

// CSETTING:<mask>:<name>[,<alias list>]:<description>
var reSetting = /CSETTING:([0-9a-fA-F]+):([_A-Za-z0-9]+)((?:,[_A-Za-z0-9]+)*):(.*)/;

// CVALUE:<value>:<name>[,<alias list>]:<description>
var reValue = /CVALUE:([0-9a-fA-F]+):([_A-Za-z0-9]+)((?:,[_A-Za-z0-9]+)*):(.*)/;

var m;
var word;
var setting;
var value;


var output=[];
var block=[];
var blockValues=[];
var defaultValue;


output.push('');
output.push('');
output.push('// config setting found in ' + sourceFile);
output.push('');
output.push('#ifndef CONFIG_H');
output.push('#define	CONFIG_H')
output.push('');
output.push('#include <xc.h>')



configDataLines.forEach(function(line){
  if(line.match(reComment)){
    // console.log("Comment", line);
  } else if(m=line.match(reWord)){

    emitBlock();

    block.push('// ' + line);
    block.push();

    word={
      address:m[1],
      mask:parseInt(m[2],16),
      default:parseInt(m[3],16),
      name:m[4],
      alias:m[5]
    };

    // console.log(word);
  }else if(m=line.match(reSetting)){
    emitBlock();
    block.push('// ' + line);

    setting={
      mask:parseInt(m[1],16),
      name:m[2],
      alias:m[3],
      description:m[4]
    };
    // console.log(setting);
  }else if(m=line.match(reValue)){

    block.push('// ' + line);

    value={
      value:parseInt(m[1],16),
      name:m[2],
      alias:m[3],
      description:m[4]
    };

    if(value.value==(setting.mask & word.default)){
      defaultValue=value;
    }

    blockValues.push(value);


  }


});

emitBlock();

output.push('');
output.push('#endif	/* CONFIG_H */');

output.forEach(function(line){
  process.stdout.write(line + '\n');
})


function emitBlock(){

  if(!setting){return;}

  //var options=blockValues.map(function(value){return value.name})
  // console.error("*********** SETTING " + setting.name + ": " + setting.description);
  //
  // blockValues.forEach(function(value){
  //   console.error(value.name,": ",value.description);
  // });
  //
  // console.error()
  //

  if(block.length){
    block.forEach(function(line){
      output.push(line);
    });
  }
  block=[];

  if(defaultValue!==undefined){
    output.push("#pragma config " + setting.name + " = " + defaultValue.name);
    output.push("");
  }

  setting=undefined;
  defaultValue=undefined;
  blockValues=[];


}
