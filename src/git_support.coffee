Shell     = require './shell'
fs        = require 'fs' 
sequence  = require 'when/sequence'
pipeline  = require 'when/pipeline'
nodefn    = require 'when/node/function'
defer     = require('when').defer
mkdirp    = require('fs-extra').mkdirp


console.log "TODO: explain pipeline and superTask"

module.exports = git =

    getConfigItem: (repo, configItem, callback) -> 

        #
        # TODO: callback error when missing repo.workDir
        #

        gitDir = "#{repo.workDir}/.git"
        
        try

            Shell.spawn null, 'git', [

                "--git-dir=#{gitDir}"
                'config'
                '--get'
                configItem

            ], (error, result) -> 

                if error then return callback error
                repo[configItem] = result.stdout.trim()
                callback null, repo

        catch error

            callback error



    getHEAD: (repo, callback) -> 

        #
        # TODO: callback error when missing repo.workDir
        #

        gitDir = "#{repo.workDir}/.git"

        fs.readFile "#{gitDir}/HEAD", (error, data) ->

            if error then return callback error
            try
                repo.HEAD = data.toString().match(/ref: (.*)\n$/)[1]
            catch error
                return callback error

            callback null, repo



    getVersion: (repo, ref, callback) -> 

        #
        # TODO: callback error when missing repo.workDir
        #

        gitDir = "#{repo.workDir}/.git"
            
        fs.readFile "#{gitDir}/#{ref}", (error, data) ->

            if error then return callback error

            repo.version = data.toString().trim()
            callback null, repo


    getStatus: (repo, callback) -> 

        repo.status ||= {}
        if repo.status['missing repo'] then return callback null, repo
        if repo.status['wrong branch'] then return callback null, repo

        #
        # TODO: callback error when missing repo.workDir
        #

        gitDir = "#{repo.workDir}/.git"

        Shell.spawn null, 'git', [

            "--git-dir=#{gitDir}"
            "--work-tree=#{repo.workDir}"
            'status'

        ], (error, status) -> 

            if error then return callback error

            if status.stdout.match /branch is ahead/

                #
                # `git status` reports eratically:
                # 
                # "Your branch is ahead of \'origin/develop\' by N commits"
                # 
                # - sometimes it is ahead and does not say so
                # - sometimes it is not ahead but says it is
                #

                repo.status['unpushed changes'] = true
                repo.status.latest = 'unpushed changes'
                repo.status.tenor  = 'bad'
                repo.status.detail = status.stdout
                return callback null, repo


            if status.stdout.match /nothing to commit \(working directory clean\)/

                repo.status['no changes'] = true
                repo.status.latest = 'no changes'
                repo.status.tenor  = 'normal'
                repo.status.detail = status.stdout
                return callback null, repo


            repo.status['has changes'] = true
            repo.status.latest = 'has changes'
            repo.status.tenor  = 'good'
            repo.status.detail = status.stdout
            callback null, repo


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

        callback null, pre_checks: missing_repo: true


    missingRepo: (repo, callback) -> 

        #
        # TODO: callback error when missing repo.workDir
        #

        gitDir  = "#{repo.workDir}/.git"
        missing = false
        missing = true unless Shell.gotDirectory gitDir

        repo.status ||= {} 
        repo.status['missing repo'] = missing
        if missing 
            repo.status.latest = 'missing repo'
            repo.status.tenor  = 'bad'

        callback null, repo


    wrongBranch: (repo, callback) -> 

        #
        # TODO: callback error when missing repo.workDir
        #

        repo.status ||= {}
        if repo.status['missing repo'] then return callback null, repo

        git.getHEAD { workDir: repo.workDir }, (error, actualRepo) ->

            wrong = repo.HEAD != actualRepo.HEAD
            repo.status ||= {} 
            repo.status['wrong branch'] = wrong
            if wrong 
                repo.status.latest = 'wrong branch'
                repo.status.tenor  = 'bad'
                repo.status.detail = "\nexpected #{repo.HEAD}\nfound #{actualRepo.HEAD}\n"

            callback null, repo


    getStagedChanges: (workDir, callback) -> 

        Shell.spawn null, 'git', [

            "--git-dir=#{workDir}/.git"
            "--work-tree=#{workDir}"
            'diff'
            '--cached'

        ], callback


    noStagedChanges: (workDir, callback) -> 

        git.getStagedChanges workDir, (error, result) -> 

            return callback 'nothing staged' if result.stdout == ''
            callback null


    status: (superTask, repo, args, callback) -> 

        console.log 'TODO: add superTask as arg1 TO ALL'

        input = 

            workDir: repo.workDir
            HEAD:    repo.HEAD

        pipeline( [

            (        ) -> nodefn.call git.missingRepo, input
            (assemble) -> nodefn.call git.wrongBranch, assemble
            (assemble) -> nodefn.call git.getStatus,   assemble

        ] ).then(

            (assembled) -> 

                latest = assembled.status.latest
                tenor  = assembled.status.tenor || 'normal'

                if latest == 'no changes'
                    superTask.notify.info[tenor] latest, 
                        description: assembled.workDir

                else 
                    superTask.notify.info[tenor] latest, 
                        description: assembled.workDir
                        detail: assembled.status.detail

                callback null, assembled

            (error)  -> callback error

        )


    clone: (superTask, workDir, origin, branch, callback) -> 

        #
        # [1] TODO: use pipeline instead, or something that
        #           can stop the sequence more gracefully
        #


        cloneArgs    = ['clone', origin, workDir]

        console.log 'TODO: report on mkdirp'

        sequence( [

            -> nodefn.call mkdirp, workDir
            -> nodefn.call git.needClone, workDir  # [1]
            -> nodefn.call Shell.spawn, superTask, 'git', ['clone', origin, workDir]
            -> nodefn.call Shell.spawn, superTask, 'git', git.checkoutArgs(workDir, branch)

            #
            # TODO: it could become necessary to step over the 'already cloned' but 
            #       still need to do the checkout
            #


        ] ).then(

            (resultArray) -> callback null, resultArray
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


    commit: (superTask, workDir, origin, branch, logMessage, callback) -> 

        sequence( [

            -> nodefn.call git.missingRepo, workDir
            -> nodefn.call git.wrongBranch, workDir, branch
            -> nodefn.call git.noStagedChanges, workDir
            -> nodefn.call Shell.spawn, superTask, 'git', git.commitArgs(workDir, logMessage)

        ] ).then(

            (resultArray) -> 

                commited = resultArray[3]

                superTask.notify.info.normal 'committed', commited
                callback null, resultArray

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

    pull: (superTask, workDir, origin, branch, callback) -> 

        sequence( [

            -> nodefn.call git.missingRepo, workDir
            -> nodefn.call git.wrongBranch, workDir, branch
            -> nodefn.call Shell.spawnAt, superTask, directory: workDir, 'git', ['pull', origin, branch]

        ] ).then(

            (resultArray) -> 

                pulled = resultArray[2]

                console.log 'pull result', pulled
                callback null, resultArray

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


