spawn  = require('child_process').spawn
fs     = require 'fs-extra'
defer  = require('when').defer

module.exports = shell = 

    gotDirectory: (directory) -> 

        try 

            return fs.lstatSync( directory ).isDirectory()             

        catch error

            return false


    spawn: (superTask, command, opts, callback) -> 

        #
        # not for long running or very talkative processes
        # stdout and stderr acumulate to string... RAM!!
        # 
        # calls back with error
        # or error = null and result = { code: 0, stdout: '', stderr: ''}
        #

        try 
            superTask.notify.info.normal 'shell', "run #{command} #{opts.join(' ')}"

        child = spawn command, opts

        stdout = ''
        stderr = ''

        child.stdout.on 'data', (data) -> 
            str = data.toString()
            stdout += str
            try superTask.notify.stdio.good str

        child.stderr.on 'data', (data) -> 
            str = data.toString()  
            stderr += str
            try superTask.notify.stdio.bad str


        child.on 'close', (code, signal) ->

            if code > 0 

                callback new Error "'#{command} #{opts.join(' ')}'" + ' exited with errorcode: ' + code

            else 

                callback null, 
                    code: code
                    stdout: stdout
                    stderr: stderr


    spawnAt: (superTask, at, command, opts, callback) -> 

        unless at.directory

            callback new Error "spawnAt() requires directory: 'dir'"
            return

        originalDir = process.cwd()

        try 

            process.chdir at.directory

            superTask.notify.info.normal 'shell', "run #{command} #{opts.join(' ')}, (in #{at.directory})"

            child = spawn command, opts

            stdout = ''
            stderr = ''

            child.stdout.on 'data', (data) -> 
                str = data.toString()
                stdout += str
                if superTask then superTask.notify.stdio.good str

            child.stderr.on 'data', (data) -> 
                str = data.toString()
                stderr += str
                if superTask then superTask.notify.stdio.bad str
                

            child.on 'close', (code, signal) ->

                if code > 0

                    process.chdir originalDir
                    callback new Error "'#{command} #{opts.join(' ')}'" + ' exited with errorcode: ' + code

                else 

                    process.chdir originalDir
                    callback null, 
                        code: code
                        stdout: stdout
                        stderr: stderr

        catch error

            process.chdir originalDir
            callback error, null




