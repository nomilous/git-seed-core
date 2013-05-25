Shell     = require './shell'
colors    = require 'colors'
fs        = require 'fs' 
sequence  = require 'when/sequence'
nodefn    = require 'when/node/function'
defer     = require('when').defer
mkdirp    = require('fs-extra').mkdirp


module.exports = git =


    getOrigin: (workDir, callback) -> 

        gitDir = git.gitDir workDir
        
        try

            Shell.spawn 'git', [

                "--git-dir=#{gitDir}"
                'config'
                '--get'
                'remote.origin.url'

            ], null, (error, result) -> 

                if error then return callback error
                callback null, result.stdout.trim()

        catch error

            callback error



    getHeadRef: (workDir, callback) -> 

        gitDir = git.gitDir workDir
        fs.readFile "#{gitDir}/HEAD", (error, data) ->

            if error then return callback error
            callback null, data.toString().match(/ref: (.*)\n$/)[1]



    getHeadVersion: (workDir, callback) -> 

        gitDir = git.gitDir workDir
        git.getHeadRef workDir, (error, head) -> 

            if error then return callback error
            fs.readFile "#{gitDir}/#{head}", (error, data) ->

                if error then return callback error
                callback error, data.toString().trim()



    getStatus: (workDir, callback) -> 

        gitDir = git.gitDir workDir

        Shell.spawn 'git', [

            "--git-dir=#{gitDir}"
            "--work-tree=#{workDir}"
            'status'

        ], null, callback



    gitDir: (workDir) -> 

        workDir + '/.git'



    checkoutArgs: (workDir, branch) -> 

        [
            "--git-dir=#{workDir}/.git"
            "--work-tree=#{workDir}"
            'checkout'
            branch.replace 'refs/heads/', ''
        ]


    needClone: (workDir, callback) -> 

        gitDir = git.gitDir workDir

        if Shell.gotDirectory gitDir

            #
            # calls back with error..... [1]
            # 

            callback 'already cloned'

        else callback null 


    clone: (workDir, origin, branch, masterDefer, callback) -> 

        #
        # [1] TODO: use pipeline instead, or something that
        #           can stop the sequence more gracefully
        #


        cloneArgs    = ['clone', origin, workDir]

        sequence( [

            -> nodefn.call mkdirp, workDir
            -> nodefn.call git.needClone, workDir  # [1]
            -> nodefn.call Shell.spawn, 'git', ['clone', origin, workDir], masterDefer
            -> nodefn.call Shell.spawn, 'git', git.checkoutArgs(workDir, branch), masterDefer

            #
            # TODO: it could become necessary to step over the 'already cloned' but 
            #       still need to do the checkout
            #


        ] ).then(

            (result) -> callback null, result
            (error)  -> 

                #
                # [1]..... in order to terminate the sequence
                #          ahead of making the clone
                # 
                #          but without erroring into the super
                #          sequence that is cloning the list
                #          of repos from the .git-seed file.
                #

                return callback error unless error == 'already cloned'

                masterDefer.notify.info.good 'already cloned', workDir
                callback null, {}

        )


    commit: (workDir, origin, branch, logMessage, masterDefer, callback) -> 
        
        console.log 'commit()', 

            workDir: workDir
            branch: branch
            origin: origin
            message: logMessage

        callback null, {}



    # showStagedDiffs: (workDir) -> 

    #     return Shell.execSync(

    #             "git --git-dir=#{workDir}/.git --work-tree=#{workDir} diff --cached", false

    #     )

    # hasStagedChanges: (workDir) -> 

    #     0 != git.showStagedDiffs( workDir ).length



    # commit: (workDir, branch, message, finalCallback) ->


    #     # waterfall [

    #     #     (callback) -> 

    #     #         skip = false

    #     #         if Shell.gotDirectory workDir

    #     #             callback null, skip

    #     #         else

    #     #             console.log '( SKIPPED )'.red, 'missing repo', workDir.bold
    #     #             callback null, skip = true

    #     #     (skip, callback) -> 

    #     #         if skip

    #     #             callback null, skip
    #     #             return

    #     #         currentBranch = git.showBranch( workDir )

    #     #         if currentBranch == branch

    #     #             callback null, skip

    #     #         else 

    #     #             console.log '( SKIPPED )'.red, workDir.bold, 'SHOULD BE ON BRANCH', branch.red, 'NOT', currentBranch.red
    #     #             callback null, skip = true



    #     #     (skip, callback) -> 

    #     #         if skip

    #     #             callback null, skip
    #     #             return

    #     #         unless git.hasStagedChanges workDir

    #     #             console.log '(skip)'.green, 'no staged changes in', workDir
    #     #             callback null
    #     #             return

    #     #         Shell.spawn 'git', [

    #     #             "--git-dir=#{workDir}/.git" # concerned about spaces in names
    #     #             "--work-tree=#{workDir}"
    #     #             'commit'
    #     #             '-m'
    #     #             message

    #     #         ], callback



    #     # ], finalCallback


    # pull: (workDir, origin, branch, ref, finalCallback) -> 

        
    #     # waterfall [ 
            
    #     #     (callback) -> 

    #     #         skip = false

    #     #         if Shell.gotDirectory workDir

    #     #             callback null, skip

    #     #         else

    #     #             console.log '( SKIPPED )'.red, 'missing repo', workDir.bold
    #     #             callback null, skip = true


    #     #     (skip, callback) -> 

    #     #         if skip

    #     #             callback null, skip
    #     #             return

    #     #         currentBranch = git.showBranch( workDir )

    #     #         if currentBranch == branch

    #     #             callback null, skip

    #     #         else 

    #     #             console.log '( SKIPPED )'.red, workDir.bold, 'SHOULD BE ON BRANCH', branch.red, 'NOT', currentBranch.red
                    
    #     #             #
    #     #             # error if root repo is on the wrong branch
    #     #             #

    #     #             if workDir == '.'

    #     #                 callback new Error( 'Root repo on wrong branch!' ), null
                    
    #     #             else

    #     #                 callback null, skip = true


    #     #     (skip, callback) -> 

    #     #         if skip

    #     #             callback null, skip
    #     #             return

    #     #         if git.showRef( workDir ) == ref

    #     #             console.log '(skip)'.green, workDir, 'already up-to-date'.green, 'with .git-seed'
    #     #             callback null
    #     #             return

    #     #         Shell.spawnAt directory: workDir, 'git', [

    #     #             "pull"
    #     #             origin
    #     #             branch

    #     #         ], callback


    #     # ], finalCallback





