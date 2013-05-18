require('nez').realize 'GitSupport', (GitSupport, test, it, should) -> 

    repoDir = __dirname + '/../'

    it 'can get repo origin', (done) -> 

        GitSupport.getOrigin repoDir, (error, origin) ->  

            origin.should.equal 'git@github.com:nomilous/git-seed-core.git'
            test done


    it 'can get repo head ref', (done) -> 

        GitSupport.getHeadRef repoDir, (error, head) -> 

            head.should.match /^refs/
            test done

    it 'can get repo ref version', (done) -> 


        GitSupport.getHeadVersion repoDir, (error, md5thing) -> 

            should.exist md5thing
            test done
    