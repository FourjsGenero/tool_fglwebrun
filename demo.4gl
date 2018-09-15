MAIN 
  DISPLAY "arg1:",arg_val(1),",arg2:",arg_val(2)
  MESSAGE "arg1:",arg_val(1),",arg2:",arg_val(2)
  MENU 
    COMMAND "Long Sleep"
      SLEEP 10
    COMMAND "Test"
      MESSAGE "TEST"
    ON IDLE 10
      MESSAGE "IDLE"
    COMMAND "EXIT"
      EXIT MENU
  END MENU
END MAIN
