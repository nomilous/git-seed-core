// Generated by CoffeeScript 1.4.0
var defer, fs, shell, spawn;

spawn = require('child_process').spawn;

fs = require('fs-extra');

defer = require('when').defer;

module.exports = shell = {
  gotDirectory: function(directory) {
    try {
      return fs.lstatSync(directory).isDirectory();
    } catch (error) {
      return false;
    }
  },
  spawn: function(superTask, command, opts, callback) {
    var child, stderr, stdout;
    try {
      superTask.notify.info.normal('shell', "run " + command + " " + (opts.join(' ')));
    } catch (_error) {}
    child = spawn(command, opts);
    try {
      if ((superTask.allow_stdio != null) && superTask.allow_stdio) {
        child.stdout.pipe(process.stdout);
        child.stderr.pipe(process.stderr);
      }
    } catch (_error) {}
    stdout = '';
    stderr = '';
    child.stdout.on('data', function(data) {
      var str;
      str = data.toString();
      return stdout += str;
    });
    child.stderr.on('data', function(data) {
      var str;
      str = data.toString();
      return stderr += str;
    });
    return child.on('close', function(code, signal) {
      try {
        superTask.allow_stdio = false;
      } catch (_error) {}
      if (code > 0) {
        return callback(new Error(("'" + command + " " + (opts.join(' ')) + "'") + ' exited with errorcode: ' + code));
      } else {
        return callback(null, {
          code: code,
          stdout: stdout,
          stderr: stderr
        });
      }
    });
  },
  spawnAt: function(superTask, at, command, opts, callback) {
    var child, originalDir, stderr, stdout;
    if (!at.directory) {
      callback(new Error("spawnAt() requires directory: 'dir'"));
      return;
    }
    originalDir = process.cwd();
    try {
      process.chdir(at.directory);
      try {
        superTask.notify.info.normal('shell', "run " + command + " " + (opts.join(' ')) + ", (in " + at.directory + ")");
      } catch (_error) {}
      child = spawn(command, opts);
      if ((superTask.allow_stdio != null) && superTask.allow_stdio) {
        child.stdout.pipe(process.stdout);
        child.stderr.pipe(process.stderr);
      }
      stdout = '';
      stderr = '';
      child.stdout.on('data', function(data) {
        var str;
        str = data.toString();
        return stdout += str;
      });
      child.stderr.on('data', function(data) {
        var str;
        str = data.toString();
        return stderr += str;
      });
      return child.on('close', function(code, signal) {
        process.chdir(originalDir);
        superTask.allow_stdio = false;
        if (code > 0) {
          return callback(new Error(("'" + command + " " + (opts.join(' ')) + "'") + ' exited with errorcode: ' + code));
        } else {
          return callback(null, {
            code: code,
            stdout: stdout,
            stderr: stderr
          });
        }
      });
    } catch (error) {
      process.chdir(originalDir);
      return callback(error, null);
    }
  }
};
