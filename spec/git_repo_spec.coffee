require('nez').realize 'GitRepo', (GitRepo, test, it, should, GitSupport, findit) -> 

    #
    # Mocks
    #

    GitSupport.showOrigin = -> 'ORIGIN'
    GitSupport.showBranch = -> 'BRANCH'
    GitSupport.showRef    = -> 'REF'

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



    it 'initializes a GitRepo from the actual repo in the specified dir', (done) ->

        repo = GitRepo.init( '.', 1 )

        repo.origin.should.equal 'ORIGIN'
        repo.root.should.equal false
        repo.branch.should.equal 'BRANCH'
        repo.ref.should.equal 'REF'

        test done

    it 'creates the repo as root if the seq is zero', (done) -> 

        GitRepo.init( '.', 0 ).root.should.equal true
        test done


    it 'defines search() to recurse for nested repos', (done) -> 

        GitRepo.search.should.be.an.instanceof Function
        test done


    it 'callsback with an array of found repositories and notifies the deferral on each', (done) -> 

        found = []

        callback = (error, result) -> 

            found[0].should.equal 'pretend/repo/.git'
            found[1].should.equal 'pretend/repo/node_modules/deeper/.git'

            result[0].constructor.name.should.equal 'GitRepo'
            result[0].root.should.equal true
            result[1].root.should.equal false
            result.length.should.equal 2
            test done

        GitRepo.search 'PATH', { Package: GitRepo }, {

            notify: (status) -> found.push status.cli.message

        }, callback


