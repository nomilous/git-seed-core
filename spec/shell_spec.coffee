require('nez').realize 'Shell', (Shell, test, context, should) -> 

    context 'dependancies', (it) -> 

        it 'does not use exec-sync', (done) -> 

            Error = ''

            try 

                require 'exec-sync'

            catch error

                Error = error

            Error.should.match /Cannot find module/ 
            test done

    
    context 'tools', (it) -> 

        it 'can mkdir -p', (done) -> 

            Shell.makeDirectory()

        it 'can exec syncronously', (done) -> 

            Shell.execSync()

        it 'can test for directory', (done) -> 

            Shell.gotDirectory('.').should.equal true
            Shell.gotDirectory('./not').should.equal false
            test done

        