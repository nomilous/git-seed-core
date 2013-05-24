console.log 'remove colors'
spawn  = require('child_process').spawn
colors = require 'colors' 
fs     = require 'fs-extra'
defer  = require('when').defer

module.exports = shell = 

    gotDirectory: (directory) -> 

        try 

            return fs.lstatSync( directory ).isDirectory()

        catch error

            return false


    spawn: (command, opts, masterDefer, callback) -> 

        #
        # not for long running or very talkative processes
        # stdout and stderr acumulate to string... RAM!!
        # 
        # calls back with error
        # or error = null and result = { code: 0, stdout: '', stderr: ''}
        #

        if masterDefer and typeof masterDefer.notify == 'function'

            masterDefer.notify

                cli:
                    context: 'normal'
                    event: 'shell'
                    detail: "#{command} #{opts.join(' ')}"

        child = spawn command, opts

        stdout = ''
        stderr = ''
        child.stdout.on 'data', (data) -> stdout += data.toString()
        child.stderr.on 'data', (data) -> stderr += data.toString()

        child.on 'close', (code, signal) ->

            if code > 0 

                callback new Error "'#{command} #{opts.join(' ')}'" + ' exited with errorcode: ' + code

            else 

                callback null, 
                    code: code
                    stdout: stdout
                    stderr: stderr


    spawnAt: (at, command, opts, masterDefer, callback) -> 

        unless at.directory

            callback new Error "spawnAt() requires directory: 'dir'"
            return

        originalDir = process.cwd()

        try 

            process.chdir at.directory

            console.log '(run)'.bold, command, opts.join(' '), "(in #{at.directory})"

            child = spawn command, opts

            stdout = ''
            stderr = ''
            child.stdout.on 'data', (data) -> stdout += data.toString()
            child.stderr.on 'data', (data) -> stderr += data.toString()

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




