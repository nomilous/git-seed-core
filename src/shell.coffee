spawn  = require('child_process').spawn
colors = require 'colors' 
fs     = require 'fs'

module.exports = shell = 

    gotDirectory: (directory) -> 

        try 

            return fs.lstatSync( directory ).isDirectory()

        catch error

            return false

    makeDirectory: (directory) ->

        throw Error 'makeDirectory()'
        # try

        #     exec "mkdir -p #{directory}"

        # catch error

        #     console.log error.red
        #     throw error


    spawn: (command, opts, callback) -> 

        #
        # not for long running or very talkative processes
        # stdout and stderr acumulate to string... RAM!!
        # 
        # calls back with error
        # or error = null and result = { code: 0, stdout: '', stderr: ''}
        #

        console.log '(run)'.bold, command, opts.join ' '

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


    spawnAt: (at, command, opts, callback) -> 

        unless at.directory

            callback new Error "spawnAt() requires directory: 'dir'"
            return

        originalDir = process.cwd()

        try 

            process.chdir at.directory

            console.log '(run)'.bold, command, opts.join(' '), "(in #{at.directory})"

            child = spawn command, opts

            #
            # TODO: optionally read these into result
            #

            child.stdout.pipe process.stdout
            child.stderr.pipe process.stderr

            child.on 'close', (code, signal) ->

                if code > 0

                    process.chdir originalDir
                    callback new Error "'#{command} #{opts.join(' ')}'" + ' exited with errorcode: ' + code

                else 

                    process.chdir originalDir
                    callback null


        catch error

            process.chdir originalDir
            callback error, null




