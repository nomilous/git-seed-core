require 'colors'
console.log 'remove colors'
GitSupport = require './git_support'
Shell      = require './shell'
Findit     = require 'findit'
w          = require 'when'

class GitRepo

    #
    # package manager plugin
    #

    @manager: -> 'none'


    @search: (rootRepoDir, Plugin, masterDefer, callback) -> 

        #
        # Search for nested repos
        # 
        # <masterDefer> Attached to a controling daemon/cli
        #               Mainly for notification
        # 
        # <callback>    Um, mid refactor...
        #               callback with array of GitRepo's (these)
        # 

        arrayOfGitWorkdirs = []
        list   = {}
        find   = Findit.find rootRepoDir


        find.on 'directory', (dir, stat) -> 

            if match = dir.match /(.*)\/.git\//

                return unless typeof list[match[1]] == 'undefined'

                masterDefer.notify

                    #
                    # build actual notification system later
                    # just for cli for now
                    #

                    cli: 

                        context: 'good'
                        event: 'found repo'
                        detail: "#{match[1]}/.git"


                list[match[1]] = 1
                arrayOfGitWorkdirs.push match[1]


        find.on 'end', ->

            seq = 0
            packages = []
            promises = []

            for path in arrayOfGitWorkdirs

                defer = w.defer()
                promises.push defer.promise
                defer.promise.then( 

                    success = (repo) -> packages.push repo
                    error = (reason) -> # hmmm... getting lazy...  

                )
                Plugin.Package.init path, seq++, masterDefer, defer


            w.all( promises ).then(

                success = -> callback null, packages
                error = (reason) -> callback reason

            )

    @init: (repoDir, seq, masterDefer, defer) -> 

        #
        # Initialise from repo in repoDir
        # 
        # <masterDefer> Attached to controling daemon/cli
        #               Mainly for notification
        # 
        # <defer>       To be resolved with the repo details
        #               or rejected.
        # 

        repo = 
            root: seq == 0
            path: repoDir
            manager: @manager()


        #
        # create '"sub"' deferrals for all 
        # the calls requireing async lookup 
        #

        originDefer  = w.defer()
        branchDefer  = w.defer()
        versionDefer = w.defer()



        #
        # pend repo resolve to after all 
        # '"sub"' deferrals are resolved
        #

        w.all([

            originDefer.promise
            branchDefer.promise
            versionDefer.promise

        ]).then -> defer.resolve repo



        #
        # each callback resolves its '"sub"' deferral
        #

        GitSupport.getOrigin repoDir, (error, origin) -> 
            repo.origin = origin
            originDefer.resolve()

        GitSupport.getHeadRef repoDir, (error, branch) -> 
            repo.branch = branch
            branchDefer.resolve()

        GitSupport.getHeadVersion repoDir, (error, version) -> 
            repo.version = version
            versionDefer.resolve()


    constructor: (properties) ->

        #console.log 'construct git repo:', arguments

        for property of properties

            @[property] = properties[property]

            if property == 'ref' and @root

                #
                # root repo has special ref
                # 
                # - no need to carry the root repo ref
                # - catch22 on root commit if we do
                # 

                @[property] = 'ROOT_REPO_REF'


    printMissing: -> 

        console.log "(MISSING) repo: #{@path}".red
        false


    printStatus: -> 

        unless Shell.gotDirectory @path + '/.git'
            
            return @printMissing()

        status = GitSupport.showStatus @path, false

        #
        # lazy moment (revist this properly)
        #

        show = true

        if status.match /nothing to commit \(working directory clean\)/

            show = false

        if status.match /Your branch is ahead/

            show = true

        if show

            console.log '\n(change)'.green, @path.bold
            console.log status + '\n'

        else

            console.log '(skip)'.green, "no change at #{@path}"


    clone: (callback) ->

        GitSupport.clone @path, @origin, @branch, callback


    commit: (message, callback) -> 

        GitSupport.commit @path, @branch, message, callback


    pull: (callback) -> 

        GitSupport.pull @path, @origin, @branch, @ref, callback


    install: (callback) -> 

        console.log '(skip)'.red, "plugin did not override GitRepo.install()"
        callback null, null
        


module.exports = GitRepo
