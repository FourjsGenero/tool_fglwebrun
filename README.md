# fglwebrun
fglwebrun - run GBC apps from the command line

# Motivation

Are you tired of writing .xcf files and starting httpdispatch on the command line ?

Then fglwebrun is the right tool for you.
It is (almost) as easy as 
```
$ fglrun prog arg1 arg2
```
, just call your program with

```
$ fglwebrun prog arg1 arg2
```

Prerequisites:
httpdispatch + GBC needs to be installed and
the FGLASDIR environment variable needs to be set.
(assuming GBC in $FGLASDIR/web/gbc-js)

# How it works

1. fglwebrun creates an xcf file with a copy of the current environment and adds also program arguments if the invocation was with arguments.
2. fglwebrun checks httpdispatch on port 6395 ( the default GAS port is 6394 ).
If it is not up and running it starts it on demand (with the option to output on stdout) 
3. It opens your default browser pointing to the suitable URL for the created xcf: voila, you should see the app, and DISPLAY statements appear on stdout like via GDC.

# Installation

You don't necessarily need to install fglwebrun.
If you did check out this repository you can call
```
$ <path_to_this_repository>/fglwebrun <yourprogram> ?arg? ?arg?
```
and it uses the fglcomp/fglrun in your PATH to compile and run fglwebrun.
Of course you can add also <path_to_this_repository> in your PATH .

# Environment Variables

BROWSER - Set this to override the default browser

Example on Mac running the app with Google Chrome:
```
$ BROWSER=/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome fglwebrun prog
```

CATEGORIES_FILTER - Set this to override the GAS categories_filter option,
default is "PROCESS", other possible values are `"ALL" and "ERROR"

Example enabling all log output of GAS
```
$ CATEGORIES_FILTER=ALL fglwebrun prog
```

# Known problems

If httpdispatch was started in the current terminal it may occasionally pollute this terminal with unwanted output even if the started app did already terminate.
Unfortunately there is no httpdispatch configuration equivalent to a GDC started with -X option (terminate after the last fglrun closed the connection...)
The only solution is to kill httpdispatch manually.

