#+ periodically checks if our GAS still has sessions
#+ if there are no sessions we kill the GAS
OPTIONS
SHORT CIRCUIT
IMPORT os
IMPORT FGL fglwebrun
MAIN
  DEFINE gasadmin, pidfile STRING
  DEFINE adminport INT
  DEFINE foundSession BOOLEAN
  IF num_args()<3 THEN
    CALL fglwebrun.myerr("usage:fglwebrunwatch:<gasadmin> <adminport> <pidfile>")
  END IF
  LET gasadmin = arg_val(1)
  IF gasadmin IS NULL
      OR NOT os.Path.exists(gasadmin)
      OR NOT os.Path.executable(gasadmin) THEN
    CALL fglwebrun.myerr(
        SFMT("fglwebrunwatch:gasadmin problem with path '%1'", arg_val(1)))
  END IF
  LET adminport = arg_val(2)
  IF adminport IS NULL OR adminport < 1024 THEN
    CALL fglwebrun.myerr(
        SFMT("fglwebrunwatch:port problem with port '%1'", arg_val(2)))
  END IF
  LET pidfile = arg_val(3)
  IF pidfile IS NULL OR NOT os.Path.exists(pidfile) THEN
    CALL fglwebrun.myerr(
        SFMT("fglwebrunwatch:pidfile problem with path '%1'", arg_val(3)))
  END IF
  WHILE TRUE
    SLEEP 1
    LET foundSession=fglwebrun.hasGASSession(gasadmin, adminport)
    IF foundSession IS NULL THEN
      RETURN
    END IF
    IF NOT foundSession THEN
      CALL fglwebrun.terminateGAS("No sessions left", pidfile)
      EXIT WHILE
    END IF
  END WHILE
END MAIN

