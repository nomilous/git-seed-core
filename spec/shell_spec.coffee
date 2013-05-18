require('nez').realize 'Shell', (Shell, test, context, should) -> 
    
    context 'tools', (it) -> 

        it 'can mkdir -p', (done) -> 

            Shell.makeDirectory()

        it 'can test for directory', (done) -> 

            Shell.gotDirectory('.').should.equal true
            Shell.gotDirectory('./not').should.equal false
            test done

        