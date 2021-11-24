# fglwebrun
fglwebrun - run GBC web apps from the command line

# Motivation

Are you tired of writing .xcf files and starting httpdispatch on the command line ?
Tired of renamed options in as.xcf/appname.xcf when the GAS version changes ?

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
FGL+GAS >=2.41

The FGLASDIR environment variable for the GAS install location needs to be set.

For GAS < 3.0 GWC HTML5 is started.

From GAS >= 3.0 GBC >=1.20 needs to be installed (assuming GBC in $FGLASDIR/web/gbc-js).

Since GAS3.10 GBC is *also* searched in $FGLDIR/web_utilities/gbc/gbc 

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

## `BROWSER`- override the default browser
Possible values
* `chrome` - launches Chrome
* `firefox` - launches Firefox
* `none` - use this when logged in via `ssh` to only start the GAS, create the `.xcf` and print the URL (the URL can be pasted into your local browser)
* `gdc` - use this when logged in via `ssh` and `FGLSERVER` is pointing to your desktop GDC (can be a port forwarded `FGLSERVER`)

Example on Mac running the app with Google Chrome:
```
$ BROWSER="chrome" fglwebrun prog
```
Example if logged in remote and `FGLSERVER` is pointing to a GDC on your desk
```
$ BROWSER="gdc" fglwebrun prog
```

## `FGLGBCDIR`- sets a custom GBC directory with your customization

Example with a specific GBC directory:
```
$ FGLGBCDIR=/Users/leo/gbc-1.00.43/dist/customization/mygbc fglwebrun prog
```
## `FGLCOMPUTER`- override the default browser hostname
On Unix (Linux/Mac) `fglwebrun` uses the `hostname` command to deduce the host GAS is running on.
Windows : `localhost` for now.
In case you want to make a port forwarding in the remote login case you might want to set it to `localhost`
```
$ ssh -L 6395:localhost:6395
$ GASPORT=6395 FGLCOMPUTER=localhost BROWSER=gdc fglwebrun demo
```

## `HTML5`- enable the GWC HTML5 theme

On GAS versions < 3.0 this is the default
For GAS >= 3.0 you need to set this to 1 if you want the older web client
```
$ HTML5=1 fglwebrun prog
```

## `FILTER`- override the GAS categories_filter option
This is for finding GAS problems
default is `PROCESS`, other possible values are `ALL` and `ERROR` and `DEBUG`, see the GAS manual for all values.

Example enabling all log output of GAS
```
$ FILTER=ALL fglwebrun prog
```
## `GDC`- runs the program with GDC
Is more internal for GDC developers.
It's an easy way to run/debug the GDC with a Genero program via http and GAS.
Example running the progam with GDC
```
$ GDC=1 fglwebrun prog
```
Connects to a running GDC instance by inspecting FGLSERVER
```
$ GDC=/Users/leo/Applications/gdc fglwebrun prog
```
If the GDC env is a valid path name to GDC , GDC is started and runs the program

# Known problems

If httpdispatch was started in the current terminal it may occasionally pollute this terminal with unwanted output even if the started app did already terminate.
Unfortunately there is no httpdispatch configuration equivalent to a GDC started with -X option (terminate after the last fglrun closed the connection...)
The only solution is to kill httpdispatch manually.
The other solution is to just change the terminal once GAS is up and running, another invocation of fglwebrun will take the same GAS.

