require('nez').realize 'GitRepo', (GitRepo, test, it, should, GitSupport, findit) -> 

    #
    # Mocks
    #

    GitSupport.getOrigin = (dir, callback) -> callback null, 'ORIGIN'
    GitSupport.getHeadRef = (dir, callback) -> callback null, 'BRANCH'
    GitSupport.getHeadVersion = (dir, callback) -> callback null, 'REF'

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

        GitRepo.search 'PATH', { Package: GitRepo }, {

            notify: event: good: (message) -> 

        }, (err, repos) -> 

            repos.should.eql [ { 
                root: true
                path: 'pretend/repo'
                manager: 'none'
                origin: 'ORIGIN'
                branch: 'BRANCH'
                ref: 'REF' 
            }, { 
                root: false
                path: 'pretend/repo/node_modules/deeper'
                manager: 'none'
                origin: 'ORIGIN'
                branch: 'BRANCH'
                ref: 'REF' 
            } ]

            test done

    it 'constructor sets the root repo ref to ROOT_REPO_REF', (done) -> 

        repo = new GitRepo 

            root: true
            ref: 'b371c0c5680a00f1da1b1ec1824e33100f713abf'

        repo.ref.should.equal 'ROOT_REPO_REF'
        test done

