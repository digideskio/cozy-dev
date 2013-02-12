async = require 'async'
helpers = require './helpers'

Client = require("request-json").JsonClient
Client::configure = (url, password, callback) ->
    @host = url
    @post "login", password: password, (err, res, body) ->
        if err or res.statusCode != 200
            console.log "Cannot get authenticated"
        else
            callback()


module.exports = class ApplicationManager

    client: new Client ""

    checkError: (err, res, body, code, msg, callback) ->
        if err or res.statusCode isnt code
            console.log err if err?
            console.log msg
            if body?
                if body.msg?
                    console.log body.msg
                else
                    console.log body
        else
            callback()


    updateApp: (app, url, password, callback) ->
        console.log "Update #{app}..."
        @client.configure url, password, =>
            path = "api/applications/#{app}/update"
            @client.put path, {}, (err, res, body) =>
                @checkError err, res, body, 200, 'Update failed', callback

    installApp: (app, url, repoUrl, password, callback) ->
        console.log "Install started for #{app}..."
        @client.configure url, password, =>
            app_descriptor =
                name: app
                git: repoUrl

            path = "api/applications/install"
            @client.post path, app_descriptor, (err, res, body) =>
                @checkError err, res, body, 201, 'Install failed', callback

    uninstallApp: (app, url, password, callback) ->
        console.log "Uninstall started for #{app}..."
        @client.configure url, password, =>
            path = "api/applications/#{app}/uninstall"
            @client.del path, (err, res, body) =>
                @checkError err, res, body, 200, 'Uninstall failed', callback

    checkStatus: (url, password, callback) ->
        checkApp = (app) =>
            (next) =>
                if app isnt "home" and app isnt "proxy"
                    path = "apps/#{app}/"
                else path = ""

                @client.get path, (err, res) ->
                    if err or res.statusCode != 200
                        console.log "#{app}: " + "down".red
                    else
                        console.log "#{app}: " + "up".green
                    next()

        checkStatus = =>
            async.series [
                checkApp("home")
                checkApp("proxy", "routes")
            ], =>
                @client.get "api/applications/", (err, res, apps) =>
                    if err
                        console.log err
                    else
                        funcs = []
                        if apps? and typeof apps == "object"
                            funcs.push checkApp(app.name) for app in apps.rows
                            async.series funcs, ->
                                callback()
     
        @client.configure url, password, checkStatus


    isInstalled: (app, url, password, callback) =>
        @client.configure url, password, =>
            @client.get "apps/#{app.toLowerCase()}/", (err, res, body) ->
                callback err, res.statusCode == 200
