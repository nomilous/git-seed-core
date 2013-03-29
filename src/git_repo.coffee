require 'colors'
GitSuport = require './git_support'
Shell     = require './shell'
Findit    = require 'findit'

class GitRepo

    @init: (repoDir, seq) -> 

        #
        # Initialise from repo in workDir
        #

        return new GitRepo

            root:    seq == 0
            path:    repoDir
            origin:  GitSuport.showOrigin repoDir
            branch:  GitSuport.showBranch repoDir
            ref:     GitSuport.showRef repoDir


    @search: (rootRepoDir, Plugin, callback) -> 

        #
        # Search for nested repos
        #

        arrayOfGitWorkdirs = []
        list  = {}
        find  = Findit.find rootRepoDir

        find.on 'directory', (dir, stat) -> 

            if match = dir.match /(.*)\/.git\//

                return unless typeof list[match[1]] == 'undefined'

                console.log '(found)'.green, "#{match[1]}/.git"
                list[match[1]] = 1
                arrayOfGitWorkdirs.push match[1]


        find.on 'end', ->

            packages = []
            seq = 0

            for path in arrayOfGitWorkdirs

                packages.push Plugin.Package.init path, seq++

            callback null, packages


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

        status = GitSuport.showStatus @path, false

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

        GitSuport.clone @path, @origin, @branch, callback


    commit: (message, callback) -> 

        GitSuport.commit @path, @branch, message, callback


    pull: (callback) -> 

        GitSuport.pull @path, @origin, @branch, callback


    install: (callback) -> 

        console.log '(skip)'.red, "plugin did not override GitRepo.install()"
        callback null, null
        


module.exports = GitRepo
