Shell     = require './shell'
colors    = require 'colors'
waterfall = require('async').waterfall

module.exports = git =

    showOrigin: (workDir) -> 

        gitDir = git.gitDir workDir
        
        try

            return Shell.execSync(

                "git --git-dir=#{gitDir} config --get remote.origin.url"

            )

        catch error

            console.log error.red
            throw error


    showBranch: (workDir) -> 

        gitDir = git.gitDir workDir

        try

            return Shell.execSync(

                "cat #{gitDir}/HEAD", false

            ).match(

                /ref: (.*)$/

            )[1]

        catch error

            console.log error.red
            throw error


    showRef: (workDir) -> 

        gitDir = git.gitDir workDir
        branch = git.showBranch workDir

        try

            return Shell.execSync(

                "cat #{gitDir}/#{branch}"

            )

        catch error

            console.log error.red
            throw error


    showStatus: (workDir, log) -> 

        gitDir = git.gitDir workDir

        try

            return Shell.execSync( 

                "git --git-dir=#{gitDir} --work-tree=#{workDir} status", log

            )

        catch error

            console.log error.red
            throw error


    gitDir: (workDir) -> 

        workDir + '/.git'


    showStagedDiffs: (workDir) -> 

        return Shell.execSync(

                "git --git-dir=#{workDir}/.git --work-tree=#{workDir} diff --cached", false

        )

    hasStagedChanges: (workDir) -> 

        0 != git.showStagedDiffs( workDir ).length


    clone: (workDir, origin, branch, finalCallback) -> 

        waterfall [

            #
            # calls in serial, proceeds no further on fail
            #

            (callback) -> 

                if Shell.gotDirectory workDir

                    callback null

                else

                    Shell.spawn 'mkdir', ['-p', workDir], callback

            (callback) -> 

                if Shell.gotDirectory "#{workDir}/.git"

                    console.log '(skip)'.green, 'already cloned', workDir
                    callback null

                else

                    Shell.spawn 'git', ['clone', origin, workDir], callback


            (callback) -> 

                if git.showBranch( workDir ) == branch

                    callback null

                else 

                    Shell.spawn 'git', [

                        "--git-dir=#{workDir}/.git" # concerned about spaces in names
                        "--work-tree=#{workDir}"
                        'checkout'
                        branch.replace 'refs/heads/', ''

                    ], callback


        ], finalCallback


    commit: (workDir, branch, message, finalCallback) ->


        waterfall [

            (callback) -> 

                skip = false

                if Shell.gotDirectory workDir

                    callback null, skip

                else

                    console.log '( SKIPPED )'.red, 'missing repo', workDir.bold
                    callback null, skip = true

            (skip, callback) -> 

                if skip

                    callback null, skip
                    return

                currentBranch = git.showBranch( workDir )

                if currentBranch == branch

                    callback null, skip

                else 

                    console.log '( SKIPPED )'.red, workDir.bold, 'SHOULD BE ON BRANCH', branch.red, 'NOT', currentBranch.red
                    callback null, skip = true



            (skip, callback) -> 

                if skip

                    callback null, skip
                    return

                unless git.hasStagedChanges workDir

                    console.log '(skip)'.green, 'no staged changes in', workDir
                    callback null
                    return

                Shell.spawn 'git', [

                    "--git-dir=#{workDir}/.git" # concerned about spaces in names
                    "--work-tree=#{workDir}"
                    'commit'
                    '-m'
                    message

                ], callback



        ], finalCallback


    pull: (workDir, origin, branch, ref, finalCallback) -> 

        
        waterfall [ 
            
            (callback) -> 

                skip = false

                if Shell.gotDirectory workDir

                    callback null, skip

                else

                    console.log '( SKIPPED )'.red, 'missing repo', workDir.bold
                    callback null, skip = true


            (skip, callback) -> 

                if skip

                    callback null, skip
                    return

                currentBranch = git.showBranch( workDir )

                if currentBranch == branch

                    callback null, skip

                else 

                    console.log '( SKIPPED )'.red, workDir.bold, 'SHOULD BE ON BRANCH', branch.red, 'NOT', currentBranch.red
                    
                    #
                    # error if root repo is on the wrong branch
                    #

                    if workDir == '.'

                        callback new Error( 'Root repo on wrong branch!' ), null
                    
                    else

                        callback null, skip = true


            (skip, callback) -> 

                if skip

                    callback null, skip
                    return

                if git.showRef( workDir ) == ref

                    console.log '(skip)'.green, workDir, 'already up-to-date with .git-seed'
                    callback null
                    return

                Shell.spawnAt directory: workDir, 'git', [

                    "pull"
                    "origin"
                    branch

                ], callback


        ], finalCallback





