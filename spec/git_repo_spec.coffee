require('nez').realize 'GitRepo', (GitRepo, test, context, should) -> 

    context 'in CONTEXT', (does) ->

        does 'an EXPECTATION', (done) ->

            test done
