IMPORT os
MAIN
  DEFINE url STRING
  IF num_args()<1 THEN
    DISPLAY "usage:fglwebrungdc <url>"
    RETURN
  END IF
  LET url=arg_val(1)
  --note that this works only if this machine is directly reachable
  CALL  openURL(url)
END MAIN

FUNCTION myerr(err)
  DEFINE err STRING
  DISPLAY "ERROR:",err
  EXIT PROGRAM 1
END FUNCTION
 
FUNCTION openURL(url)
  DEFINE url, osType,cmd STRING
  DEFINE ret INT
  CALL ui.Interface.frontCall("standard","feinfo",["osType"],[osType])
  LET osType=osType.toLowerCase()
  DISPLAY "GDC osType:",osType
  CASE
      WHEN osType=="windows" 
        LET cmd=sfmt('cmd /c "start %1"',url)
      WHEN osType MATCHES "mac*" OR osType=="OSX"
        LET cmd=sfmt("open %1",url)
      OTHERWISE --assume kinda linux
        LET cmd=sfmt("xdg-open %1",url)
  END CASE
  DISPLAY "cmd:",cmd
  CALL ui.Interface.frontcall("standard","execute",[cmd,0],[ret])
  DISPLAY "ret:",ret
END FUNCTION
