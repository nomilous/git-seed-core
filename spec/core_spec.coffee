require('nez').realize 'Core', (Core, test, it, should) -> 

    it 'exports GitRepo', (done) -> 

        Core.GitRepo.should.equal require '../lib/git_repo'
        test done
