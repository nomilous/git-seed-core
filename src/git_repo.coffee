GitSupport = require './git_support'
Shell      = require './shell'
Findit     = require 'findit'
sequence   = require 'when/sequence'
pipeline   = require 'when/pipeline'
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

    @search: (superTask, rootRepoDir, Plugin, callback) -> 

        find    = Findit.find rootRepoDir
        uniq    = {}
        found   = []
        manager = @manager()

        find.on 'directory', (dir, stat) -> 

            if match = dir.match /(.*)\/.git\//

                return unless typeof uniq[match[1]] == 'undefined'
                uniq[match[1]] = 1

                superTask.notify.info.normal 'found repo', "#{match[1]}/.git"
                found.push match[1]
        

        find.on 'end', ->

            seq   = 0
            paths = []
            tasks = sequence( for path in found 
                
                paths.unshift path
                -> nodefn.call Plugin.Package.init, superTask, paths.pop(), seq++, manager

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

    @init: (superTask, workDir, seq, manager, callback) -> 

        input = 

            root:           seq == 0
            workDir:        workDir
            packageManager: manager


        tasks = pipeline [

            (    ) -> nodefn.call GitSupport.getConfigItem, input, 'remote.origin.url'
            (repo) -> nodefn.call GitSupport.getHEAD, repo
            (repo) -> nodefn.call GitSupport.getVersion, repo, repo.HEAD

        ] 

        tasks.then(

            success = (repo) -> callback null, repo
            failed  = (error)  -> callback error

        )


    #
    # `GitRepo.status()`
    # 
    # Calls back with repo statii
    #

    @status: (superTask, repo, args, callback) -> 

        GitSupport.status superTask, repo, args, callback


    #
    # `GitRepo.clone()`
    # 
    # Performs clone
    #

    @clone: (superTask, repo, args, callback) -> 

        GitSupport.clone superTask, repo.path, repo.origin, repo.branch, callback

    #
    # `GitRepo.commit()`
    # 
    # Commits 
    #

    @commit: (superTask, repo, args, callback) -> 

        GitSupport.commit superTask, repo.path, repo.origin, repo.branch, args.message, callback

    #
    # `GitRepo.pull()`
    # 
    # Pulls 
    #

    @pull: (superTask, repo, args, callback) -> 

        GitSupport.pull superTask, repo.path, repo.origin, repo.branch, callback


    #
    # `GitRepo.install()`
    # 
    # Performs package manager install
    # Package implementations should override this
    #

    @install: (superTask, repo, args, callback) -> 

        superTask.notify.info.normal 'no package manager', ''
        callback null, {}



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
