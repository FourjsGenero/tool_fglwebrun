#+ test connector to GDC
#+ if no client is reachable: error with Cannot connect to GUI
#+ if the client is different from GDC: error wrong client
MAIN
  DEFINE executable STRING
  IF NVL(ui.Interface.getFrontEndName(),"wrong")!="GDC" THEN
    DISPLAY "wrong client:",ui.Interface.getFrontEndName()
    EXIT PROGRAM 1
  END IF
  CALL  ui.Interface.frontCall("qa","getInformation",["applicationFilePath"],[executable])
  DISPLAY executable
END MAIN
