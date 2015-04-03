ipaMetadata = require "ipa-metadata"
parseApk = require "apk-parser2"
fs = require "fs"
path = require "path"
async = require "async"

module.exports = (options = {}) =>

  templateVars =
    bundleVersion: ""
    bundleShortVersionString: ""
    bundleIdentifier: ""
    iOSName: ""
    ipaUrl: ""
    plistUrl: ""
    url: ""
    iOSDownloadUrl: ""
    iOSExpires: ""
    version: ""

    apkUrl: ""
    androidName: ""

  templateVars.url = options.url

  options.directory or = "."

  async.series [
    # read iOS Information
    (cb) =>
      if options.ipa
        ipaMetadata options.ipa, (err,data) =>
          templateVars.bundleVersion = data.metadata.CFBundleVersion or "0.0.0"
          templateVars.bundleShortVersionString = data.metadata.CFBundleShortVersionString or "0.0.0"
          templateVars.iOSName = data.metadata.CFBundleDisplayName or path.basename options.ipa, ".ipa"
          templateVars.bundleIdentifier = data.metadata.CFBundleIdentifier or ""
          templateVars.ipaUrl = "#{templateVars.url}/#{path.basename options.ipa}"
          templateVars.plistUrl = "itms-services://?action=download-manifest&url=#{templateVars.url}/manifest.plist"
          templateVars.iOSExpires = data.provisioning.ExpirationDate
          copyPath = path.join(options.directory,path.basename(options.ipa))
          copyFile options.ipa, copyPath, cb
      else
        return cb()

    # read Android Information
    (cb) =>
      if options.apk
        templateVars.androidName = templateVars.iOSName or path.basename options.apk, ".apk"
        templateVars.apkUrl = "#{templateVars.url}/#{path.basename options.apk}"
        copyPath = path.join(options.directory,path.basename(options.apk))
        copyFile options.apk, copyPath, cb
      else
        return cb()

    (cb) =>
      templateVars.version = templateVars.bundleVersion or "0.0.0"
      cb()
    # write plist
    (cb) =>
      plistTemplate = fs.readFileSync(path.join(__dirname,"../res/manifest.plist"), "utf8");
      writeFileWithVars plistTemplate, templateVars, path.join(options.directory,"manifest.plist"), cb
    # write index.html
    (cb) =>
      htmlTemplate = fs.readFileSync(options.template, "utf8");
      writeFileWithVars htmlTemplate, templateVars, path.join(options.directory,"index.html"), cb

  ], (err) =>
    if err
      console.log "[ERR]", err

  writeFileWithVars = (content, vars, target, callback) =>
    for key of templateVars
      content = content.split("{{#{key}}}").join(templateVars[key]);
    fs.writeFileSync target, content, "utf8"
    callback()

  copyFile = (source, target, cb) ->
    cbCalled = false
    rd = fs.createReadStream(source)

    done = (err) ->
      if !cbCalled
        cb err
        cbCalled = true
      return

    rd.on 'error', done
    wr = fs.createWriteStream(target)
    wr.on 'error', done
    wr.on 'close', (ex) ->
      done()
      return
    rd.pipe wr
    return
