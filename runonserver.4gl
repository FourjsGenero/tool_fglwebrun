MAIN
  DEFINE result STRING
  DEFINE starttime DATETIME HOUR TO FRACTION(1)
  DEFINE diff INTERVAL MINUTE TO FRACTION(1)
  DISPLAY "FGLSERVER=",fgl_getenv("FGLSERVER")
  LET starttime = CURRENT
  TRY
    CALL ui.Interface.frontCall("mobile","runOnServer",
          [arg_val(1),5],[result])
    DISPLAY sfmt("runOnServer returned:%1",result)
  CATCH
    LET result=err_get(status)
    DISPLAY "ERROR:",result
  END TRY
  LET diff = CURRENT - starttime
  DISPLAY "time for runOnServer:",diff
END MAIN
