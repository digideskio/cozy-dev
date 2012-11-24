require "colors"
program = require 'commander'
path = require 'path'

Client = require("request-json").JsonClient
Client::configure = (url, password, callback) ->
    @host = url
    @post "login", password: password, (err, res) ->
        if err or res.statusCode != 200
            console.log "Cannot get authenticated"
        else
            callback()

client = new Client ""

RepoManager = require('./repository').RepoManager
repoManager = new RepoManager()

ApplicationManager = require('./application').ApplicationManager
appManager = new ApplicationManager()

ProjectManager = require('./project').ProjectManager
projectManager = new ProjectManager()

### Tasks ###

program
    .version('0.1.0')
    .option('-u, --url <url>',
            'set url where lives your Cozy Cloud, default to localhost')
    .option('-g, --github <github>',
            'Link new project to github account')


program
    .command("install <app> <repo>")
    .description("Install given application from its repository")
    .action (app, repo) ->
        program.password "Cozy password:", (password) ->
            appManager.installApp app, program.url, repo, password, ->
                console.log "#{app} sucessfully installed"
          
program
    .command("uninstall <app>")
    .description("Uninstall given application")
    .action (app) ->
        program.password "Cozy password:", (password) ->
            appManager.uninstallApp app, program.url, password, ->
               console.log "#{app} sucessfully uninstalled"

program
    .command("update <app>")
    .description(
        "Update application (git + npm install) and restart it through haibu")
    .action (app) ->
        program.password "Cozy password:", (password) ->
            appManager.updateApp app, program.url, password, ->
                console.log "#{app} sucessfully updated"

program
    .command("status")
    .description("Give current state of cozy platform applications")
    .action ->
        program.password "Cozy password:", (password) ->
            appManager.checkStatus program.url, password, ->
                console.log "all apps checked."

program
    .command("new <appname>")
    .description("Create a new app suited to be deployed on a Cozy Cloud.")
    .action (appname) ->
        user = program.github

        if user?
            console.log "Create repo #{appname} for user #{user}..."
            program.password "Github password:", (password) =>
                program.prompt "Cozy Url:", (url) ->
                    projectManager.newProject appname, url, user, password, ->
                        console.log "project creation finished."
                        process.exit 0
        else
            console.log "Create project folder: #{name}"
            repoManager.createLocalRepo appname, ->
                console.log "project creation finished."

program
    .command("deploy")
    .description("Push code and deploy app located in current directory" + \
                 "to Cozy Cloud url configured in configuration file.")
    .action ->

        config = require(path.join(process.cwd(), "deploy_config")).config
        program.password "Cozy password:", (password) ->
            projectManager.deploy config, password, ->
                console.log "#{config.cozy.appName} sucessfully deployed."

program
    .command("*")
    .description("Display error message for an unknown command.")
    .action ->
        console.log 'Unknown command, run "coffee monitor --help"' + \
                    ' to know the list of available commands.'
                    
program.parse process.argv