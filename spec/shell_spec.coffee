require('nez').realize 'Shell', (Shell, test, context, should) -> 
 












    
    # context 'tools', (it) -> 

    #     it 'can test for directory', (done) -> 

    #         Shell.gotDirectory('.').should.equal true
    #         Shell.gotDirectory('./not').should.equal false
    #         test done

    #     it 'can spawn a shell process and callback', (done) -> 

    #         Shell.spawn 'echo', ['moooo'], null, (error, result) -> 

    #             result.stdout.should.match /moooo/
    #             test done
