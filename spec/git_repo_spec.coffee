require('nez').realize 'GitRepo', (GitRepo, test, it, should, GitSupport, findit) -> 

    #
    # Mocks
    #

    superTask = {

        notify: 
            event: 
                good:   (message) -> 
                normal: (message) ->
                bad:    (message) -> 
            info: 
                good:   (message) -> 
                normal: (message) ->
                bad:    (message) -> 

    }

    GitSupport.getConfigItem = (superTask, repo, configItem, callback) -> 
        repo[configItem] = 'ORIGIN' 
        callback null, repo
    GitSupport.getHEAD = (superTask, repo, callback) -> 
        repo.HEAD = 'HEAD' 
        callback null, repo
    GitSupport.getVersion = (superTask, repo, ref, callback) -> 
        repo.version = 'VERSION'
        callback null, repo

    findit.find = (path) -> 
        path.should.equal 'PATH'
        on: (event, callback) ->
            switch event
                when 'directory'

                    #
                    # pretend to find two git repos
                    #

                    callback 'pretend/repo/.git/'
                    callback 'pretend/repo/node_modules/deeper/.git/'
                
                when 'end'
                    callback()


    it 'search() finds and loads repos', (done) -> 

        GitRepo.search superTask, 'PATH', { Package: GitRepo }, (err, repos) -> 

            repos.should.eql [{ 
                root: true,
                workDir: 'pretend/repo',
                packageManager: 'none',
                'remote.origin.url': 'ORIGIN',
                HEAD: 'HEAD',
                version: 'VERSION' 
            },{             
                root: false,
                workDir: 'pretend/repo/node_modules/deeper',
                packageManager: 'none',
                'remote.origin.url': 'ORIGIN',
                HEAD: 'HEAD',
                version: 'VERSION' 
            } ]
            
            test done

    it 'constructor sets the root repo ref to ROOT_REPO_REF', (done) -> 

        repo = new GitRepo 

            root: true
            ref: 'b371c0c5680a00f1da1b1ec1824e33100f713abf'

        repo.ref.should.equal 'ROOT_REPO_REF'
        test done

