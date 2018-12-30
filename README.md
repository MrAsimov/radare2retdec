radare2retdec
=============

Created a Docker setup so it is easy to install radare2 and retdec and combine them through the retdec plugin for radare2 usage so it's easy to see assembly instructions as 'human' C code in radare2 when you are reverse engineering the binary file.

Installation
============

Docker
------
```
docker build -t r2docker:latest .
```

Docker use
----------

user = user's home directory in a Linux system
    
binary path = the location where the user stores his/her binary file(s)
    
```
docker run -ti -v /home/<user>/<binary path>:/<binary path> --cap-drop=ALL r2docker:latest r2 /<binary path>/<Program>/file
```

Example

```
docker run -ti -v /Users/andy/binaries:/binaries --cap-drop=ALL r2docker:latest r2 /binaries/Stellaris/stellaris
```

radare2 & retdec demo usage
===========================

[![asciicast](https://asciinema.org/a/8dpAZnzOC8qvy3hHyx5fxFOQn.svg)](https://asciinema.org/a/8dpAZnzOC8qvy3hHyx5fxFOQn)


References
==========

These are the repositories used to be able to create this Dockerfile installation.

radare2: https://github.com/radare/radare2

retdec: https://github.com/avast-tl/retdec

r2retdec plugin for radare2: https://github.com/securisec/r2retdec
