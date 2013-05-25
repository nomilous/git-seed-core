GitSupport = require './git_support'
Shell      = require './shell'
Findit     = require 'findit'
#w          = require 'when'
sequence   = require 'when/sequence'
nodefn     = require 'when/node/function'

class GitRepo

    #
    # package manager plugin
    #

    @manager: -> 'none'


    #
    # `GitRepo.search()`
    # 
    # Calls back with array of initialized GitRepo(s)
    #

    @search: (rootRepoDir, Plugin, masterDefer, callback) -> 

        find    = Findit.find rootRepoDir
        uniq    = {}
        found   = []
        manager = @manager()

        find.on 'directory', (dir, stat) -> 

            if match = dir.match /(.*)\/.git\//

                return unless typeof uniq[match[1]] == 'undefined'
                uniq[match[1]] = 1

                masterDefer.notify.info.good 'found repo', "#{match[1]}/.git"
                found.push match[1]
        

        find.on 'end', ->

            seq   = 0
            paths = []
            tasks = sequence( for path in found 
                
                paths.unshift path
                -> nodefn.call Plugin.Package.init, paths.pop(), seq++, manager, masterDefer

            )

            tasks.then( 

                success = (repos) -> callback null, repos
                failed  = (error) -> callback error

            )


    #
    # `GitRepo.init()`
    # 
    # Calls back with an initialized GitRepo
    #

    @init: (repoDir, seq, manager, masterDefer, callback) -> 

        tasks = sequence [

            -> nodefn.call GitSupport.getOrigin, repoDir
            -> nodefn.call GitSupport.getHeadRef, repoDir
            -> nodefn.call GitSupport.getHeadVersion, repoDir

        ] 

        tasks.then(

            success = (results) -> 

                callback null, 

                    root:    seq == 0
                    path:    repoDir
                    manager: manager
                    origin:  results[0]
                    branch:  results[1]
                    ref:     results[2]
                
            failed  = (error)  -> callback error

        )


    #
    # `GitRepo.status()`
    # 
    # Calls back with repo statii
    #

    @status: (repo, masterDefer, callback) -> 

        unless Shell.gotDirectory repo.path + '/.git'

            masterDefer.notify.info.bad 'missing repo', repo.path
            callback null, {}
            return


        GitSupport.getStatus repo.path, (error, status) -> 

            if status.stdout.match /branch is ahead/

                masterDefer.notify.info.bad 'unpushed', 
                    description: repo.path
                    detail: status.stdout
                callback null, status  
                return  



            if status.stdout.match /nothing to commit \(working directory clean\)/

                masterDefer.notify.info.good 'unchanged', repo.path 
                callback null, {}
                return

            masterDefer.notify.info.good 'changed',
                description: repo.path
                detail: status.stdout


            callback null, status


    #
    # `GitRepo.clone()`
    # 
    # Performs clone
    #

    @clone: (repo, masterDefer, callback) -> 

        GitSupport.clone repo.path, repo.origin, repo.branch, masterDefer, callback



    constructor: (properties) ->

        for property of properties

            @[property] = properties[property]

            if property == 'ref' and @root

                @[property] = 'ROOT_REPO_REF'






    # notifyMissing: (masterDefer) -> 

    #     masterDefer.notify 

    #         cli: 

    #             context: 'bad'
    #             event: 'missing repo'
    #             detail: "#{@path}"

    #     false


    # getStatus: (masterDefer) ->

    #     unless Shell.gotDirectory @path + '/.git'
            
    #         return @notifyMissing masterDefer

    #     GitSupport.getStatus @path, (error, status) => 

    #         show = true

    #         if status.stdout.match /nothing to commit \(working directory clean\)/

    #             show = false

    #         if status.stdout.match /Your branch is ahead/

    #             show = true

    #         if show

    #             context = 'good'
    #             event   = 'changed'
    #             detail  = @path + '\n' + status.stdout

    #         else
    #             context = 'good'
    #             event   = 'unchanged'
    #             detail  = @path

    #         masterDefer.notify

    #             cli:

    #                 context: context
    #                 event: event
    #                 detail: detail


    # clone: (defer) ->

    #     console.log defer
    #     #defer.resolve()

        
        

    #     # GitSupport.clone @path, @origin, @branch, masterDefer, callback


    # # commit: (message, callback) -> 

    # #     GitSupport.commit @path, @branch, message, callback


    # # pull: (callback) -> 

    # #     GitSupport.pull @path, @origin, @branch, @ref, callback


    # # install: (masterDefer, callback) -> 

    # #     masterDefer.notify 

    # #         cli:
    # #             context 'bad'
    # #             event: 'skip'
    # #             detail: 'plugin did not override GitRepo.install()'

    # #     callback null, null
        


module.exports = GitRepo
