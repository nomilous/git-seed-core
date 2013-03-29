require('nez').realize 'Shell', (Shell, test, context) -> 

    context 'dependancies', (it) -> 

        it 'does not use exec-sync', (done) -> 

            try 

                require 'exec-sync'

            catch error

                error.should.match /Cannot find module/
                test done

            true.should.equal false