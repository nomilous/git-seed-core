require('nez').realize 'Core', (Core, test, it, should) -> 

    it 'exports Git support', (done) -> 

        Core.Git.should.equal require '../lib/git_support'
        test done


    it 'exports GitRepo', (done) -> 

        Core.GitRepo.should.equal require '../lib/git_repo'
        test done


    it 'exports Shell', (done) -> 

        Core.Shell.should.equal require '../lib/shell'
        test done
