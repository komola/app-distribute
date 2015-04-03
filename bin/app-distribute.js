#!/usr/bin/env node
var program = require("commander");
var version = require("../package.json").version;

program
  .version(version)
  .option('--template <template file>', 'template file (required)')
  .option('--ipa <ipa file>', 'ipa file (optional)')
  .option('--apk <apk file>', 'apk file (optional)')
  .option('--url <url>', 'the url under which the files will be hosted later (required)')
  .option('--directory <directory>', 'target directory for the generated files. If left empty current directory is assumed.')
  .parse(process.argv);

  if (!process.argv.slice(2).length) {
    program.help();
  }

  if (!program.template)
  {
    console.log("You need to specify a template file!");
    program.help();
  }

  if (!program.url)
  {
    console.log("You need to specify a url!");
    program.help();
  }

var options = {
  template: program.template,
  ipa: program.ipa,
  apk: program.apk,
  url: program.url,
  directory: program.directory
}

require("coffee-script/register");
require("../lib/distributor")(options)
