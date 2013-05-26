Shell     = require './shell'
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
            return

        callback null


    missingRepo: (workDir, callback) -> 

        gitDir = git.gitDir workDir

        unless Shell.gotDirectory gitDir
            callback 'missing repo'
            return

        callback null


    wrongBranch: (workDir, branch, callback) -> 

        git.getHeadRef workDir, (error, headRef) ->

            return callback 'wrong branch' if headRef != branch
            callback null


    getStagedChanges: (workDir, callback) -> 

        Shell.spawn 'git', [

            "--git-dir=#{workDir}/.git"
            "--work-tree=#{workDir}"
            'diff'
            '--cached'

        ], null, callback


    noStagedChanges: (workDir, callback) -> 

        git.getStagedChanges workDir, (error, result) -> 

            return callback 'nothing staged' if result.stdout == ''
            callback null


    status: (workDir, origin, branch, superTask, callback) -> 

        sequence( [

            -> nodefn.call git.missingRepo, workDir
            -> nodefn.call git.wrongBranch, workDir, branch
            -> nodefn.call git.getStatus,   workDir

        ] ).then(

            (result) -> 

                status = result[2]

                if status.stdout.match /branch is ahead/

                    #
                    # `git status` reports eratically:
                    # 
                    # "Your branch is ahead of \'origin/develop\' by N commits"
                    # 
                    # - sometimes it is ahead and does not say so
                    # - sometimes it is not ahead but says it is
                    #

                    superTask.notify.info.bad 'unpushed', 
                        description: workDir
                        detail: status.stdout
                    return callback null, status

                if status.stdout.match /nothing to commit \(working directory clean\)/

                    superTask.notify.info.normal 'unchanged', workDir
                    return callback null, status

                superTask.notify.info.good 'changed',
                    description: workDir
                    detail: status.stdout

                callback null, status

            (error)  -> 

                #
                # #duplication
                #

                if error == 'missing repo'

                    superTask.notify.info.bad 'missing repo', workDir
                    callback null, {}
                    return

                if error == 'wrong branch'

                    superTask.notify.info.bad 'wrong branch', "#{workDir} - expects #{branch}"
                    callback null, {}
                    return

                callback error


        )


    clone: (workDir, origin, branch, superTask, callback) -> 

        #
        # [1] TODO: use pipeline instead, or something that
        #           can stop the sequence more gracefully
        #


        cloneArgs    = ['clone', origin, workDir]

        sequence( [

            -> nodefn.call mkdirp, workDir
            -> nodefn.call git.needClone, workDir  # [1]
            -> nodefn.call Shell.spawn, 'git', ['clone', origin, workDir], superTask
            -> nodefn.call Shell.spawn, 'git', git.checkoutArgs(workDir, branch), superTask

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

                superTask.notify.info.good 'already cloned', workDir
                callback null, {}

        )


    commitArgs: (workDir, logMessage) -> 

        [
            "--git-dir=#{workDir}/.git"
            "--work-tree=#{workDir}"
            'commit'
            '-m'
            logMessage
        ]


    commit: (workDir, origin, branch, logMessage, superTask, callback) -> 

        sequence( [

            -> nodefn.call git.missingRepo, workDir
            -> nodefn.call git.wrongBranch, workDir, branch
            -> nodefn.call git.noStagedChanges, workDir
            -> nodefn.call Shell.spawn, 'git', git.commitArgs(workDir, logMessage), superTask

        ] ).then(

            (result) -> 

                commited = result[3]

                superTask.notify.info.normal 'committed', commited
                callback null, result

            (error)  -> 

                #
                # #duplication
                #

                if error == 'missing repo'

                    superTask.notify.info.bad 'missing repo', workDir
                    callback null, {}
                    return

                if error == 'wrong branch'

                    superTask.notify.info.bad 'wrong branch', "#{workDir} - expects #{branch}"
                    callback null, {}
                    return

                if error == 'nothing staged'

                    superTask.notify.info.normal 'nothing staged', "#{workDir}"
                    callback null, {}
                    return


                callback error

        )

    pull: (workDir, origin, branch, superTask, callback) -> 

        sequence( [

            -> nodefn.call git.missingRepo, workDir
            -> nodefn.call git.wrongBranch, workDir, branch
            -> nodefn.call Shell.spawnAt, directory: workDir, 'git', ['pull', origin, branch], superTask

        ] ).then(

            (result) -> 

                console.log 'pull result', result
                callback null, result

            (error)  -> 

                #
                # #duplication (parital)
                #

                if error == 'missing repo'

                    superTask.notify.info.bad 'missing repo', workDir
                    callback null, {}
                    return

                if error == 'wrong branch'

                    superTask.notify.info.bad 'wrong branch', "#{workDir} - expects #{branch}"
                    callback null, {}
                    return

                callback error

        )


