Shell     = require './shell'
fs        = require 'fs' 
sequence  = require 'when/sequence'
pipeline  = require 'when/pipeline'
nodefn    = require 'when/node/function'
defer     = require('when').defer
mkdirp    = require('fs-extra').mkdirp

module.exports = git =

    getConfigItem: (superTask, repo, configItem, callback) -> 

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



    getHEAD: (superTask, repo, callback) -> 

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



    getVersion: (superTask, repo, ref, callback) -> 

        #
        # TODO: callback error when missing repo.workDir
        #

        gitDir = "#{repo.workDir}/.git"
            
        fs.readFile "#{gitDir}/#{ref}", (error, data) ->

            if error then return callback error

            repo.version = data.toString().trim()
            callback null, repo


    getStatus: (superTask, repo, callback) -> 

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

    makeWorkDir: (superTask, repo, callback) -> 

        return callback null, repo if Shell.gotDirectory repo.workDir

        mkdirp repo.workDir, (err) -> 
            if err? 
                superTask.notify.info.bad 'mkdirp', 
                    "FAILED to create #{repo.workDir}"
                return callback err, null

            superTask.notify.info.normal 'mkdirp', repo.workDir
            callback err, repo


    ensureWorkDir: (superTask, repo, callback) -> 

        unless Shell.gotDirectory repo.workDir

            return git.makeWorkDir superTask, repo, callback

        callback null, repo


    ensureClone: (superTask, repo, callback) -> 

        gitDir = "#{repo.workDir}/.git"

        unless Shell.gotDirectory gitDir

            args = ['clone', repo['remote.origin.url'], repo.workDir]
            return Shell.spawn superTask, 'git', args, callback

        callback null, repo


    ensureCheckout: (superTask, repo, callback) -> 

        git.getHEAD superTask, { workDir: repo.workDir }, (error, actualRepo) ->

            if repo.HEAD != actualRepo.HEAD

                superTask.notify.info.good 'checkout', 
                    "#{repo.HEAD} in #{repo.workDir}"

                args = git.checkoutArgs(repo.workDir, repo.HEAD)
                return Shell.spawn superTask, 'git', args, callback

            callback null, repo


    missingRepo: (superTask, repo, callback) -> 

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


    wrongBranch: (superTask, repo, callback) -> 

        #
        # TODO: callback error when missing repo.workDir
        #

        repo.status ||= {}
        if repo.status['missing repo'] then return callback null, repo

        git.getHEAD superTask, { workDir: repo.workDir }, (error, actualRepo) ->

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

        input = 

            workDir: repo.workDir
            HEAD:    repo.HEAD

        pipeline( [

            (        ) -> nodefn.call git.missingRepo, superTask, input
            (assemble) -> nodefn.call git.wrongBranch, superTask, assemble
            (assemble) -> nodefn.call git.getStatus,   superTask, assemble

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


    clone: (superTask, repo, args, callback) -> 

        pipeline( [

            (        ) -> nodefn.call git.ensureWorkDir,  superTask, repo
            (assemble) -> nodefn.call git.ensureClone,    superTask, repo
            (assemble) -> nodefn.call git.ensureCheckout, superTask, repo

        ] ).then(

            (assembled) -> callback null, assembled
            (error) -> callback error

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


