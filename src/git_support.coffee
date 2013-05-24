Shell     = require './shell'
colors    = require 'colors'
fs        = require 'fs' 
sequence  = require 'when/sequence' 


module.exports = git =

    junk: ->
    

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


    # getStatus: (workDir, callback) -> 

    #     gitDir = git.gitDir workDir

    #     Shell.spawn 'git', [

    #         "--git-dir=#{gitDir}"
    #         "--work-tree=#{workDir}"
    #         'status'

    #     ], null, callback


    gitDir: (workDir) -> 

        workDir + '/.git'


    # showStagedDiffs: (workDir) -> 

    #     return Shell.execSync(

    #             "git --git-dir=#{workDir}/.git --work-tree=#{workDir} diff --cached", false

    #     )

    # hasStagedChanges: (workDir) -> 

    #     0 != git.showStagedDiffs( workDir ).length


    # clone: (workDir, origin, branch, masterDefer, finalCallback) -> 


    #     sequence( [

    #         Shell.promiseDirectory
    #         ->

    #     ], workdir ).then(

    #         -> console.log 'RESULT:', arguments
    #         -> console.log 'ERROR:', arguments

    #     ) 

    #     # waterfall [

    #     #     #
    #     #     # calls in serial, proceeds no further on fail
    #     #     #

    #     #     (callback) -> 

    #     #         if Shell.gotDirectory workDir

    #     #             callback null

    #     #         else

    #     #             Shell.makeDirectory workDir, masterDefer, (err) -> 

    #     #                 callback err

    #     #     (callback) -> 

    #     #         if Shell.gotDirectory "#{workDir}/.git"

    #     #             masterDefer.notify 

    #     #                 cli: 
    #     #                     context: 'good'
    #     #                     event:   'skip'
    #     #                     detail:  'already cloned ' + workDir

    #     #             callback null

    #     #         else

    #     #             Shell.spawn 'git', ['clone', origin, workDir], masterDefer, (err) -> 

    #     #                 callback err


    #     #     (callback) -> 

    #     #         git.getHeadRef workDir, (err, head) -> 

    #     #             if err then return callback err

    #     #             #
    #     #             # already checked out?
    #     #             # 

    #     #             if head == branch then return callback null

    #     #             Shell.spawn 'git', [

    #     #                 "--git-dir=#{workDir}/.git" # concerned about spaces in names
    #     #                 "--work-tree=#{workDir}"
    #     #                 'checkout'
    #     #                 branch.replace 'refs/heads/', ''

    #     #             ], masterDefer, (err, result) -> 

    #     #                 if err then return callback err

    #     #                 detail = result.stdout + result.stderr

    #     #                 masterDefer.notify 

    #     #                     cli: 

    #     #                         event:   'output'
    #     #                         detail:  detail

    #     #                 callback null

    #     # ], finalCallback


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





