MAIN 
  DISPLAY "arg1:",arg_val(1),",arg2:",arg_val(2)
  MESSAGE "arg1:",arg_val(1),",arg2:",arg_val(2)
  MENU 
    COMMAND "Long Sleep"
      SLEEP 3
    COMMAND "TEST Message"
      MESSAGE "TEST"
    ON IDLE 10
      MESSAGE "IDLE"
    COMMAND "Webcomponent"
      CALL webco()
    COMMAND "Exit"
      EXIT MENU
  END MENU
END MAIN

FUNCTION webco()
  DEFINE entry,w STRING
  OPEN WINDOW w WITH FORM "demo"
  LET entry="abc"
  DISPLAY entry TO entry
  LET w="def"
  DISPLAY w TO w
  MENU "Test Webco"
    COMMAND "Input"
      LET int_flag=FALSE
      INPUT BY NAME entry,w WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
        BEFORE INPUT
          CALL webcomponent_setproperty("formonly.w","active","1")
        ON CHANGE w
          MESSAGE "on change:",w
        ON ACTION next
          NEXT FIELD next
        ON ACTION show_Entry
          MESSAGE "value of entry is:",entry
        ON ACTION show_webco
          MESSAGE "value of w is:",w
        ON ACTION set_webco
          LET w="setbyprogram"
        AFTER FIELD w
          CALL ui.Interface.frontCall("webcomponent","call",["formonly.w","getData"],[w])
          DISPLAY "after field:",w
      END INPUT
      CALL webcomponent_setproperty("formonly.w","active","0")
      IF NOT int_flag THEN
        MESSAGE sfmt("w is:%1",w)
      END IF
    COMMAND "Exit"
      EXIT MENU
  END MENU
  CLOSE WINDOW w
END FUNCTION

--some boilerplate ...
FUNCTION webcomponent_findComponent(field)
  DEFINE field STRING
  DEFINE w ui.Window
  DEFINE f ui.Form
  DEFINE ff, wc om.DomNode
  LET w = ui.Window.getCurrent()
  LET f = w.getForm()
  LET ff = f.findNode("FormField",field)
  IF ff is NOT NULL THEN
    LET wc = ff.getFirstChild()
  END IF
  RETURN wc
END FUNCTION

FUNCTION webcomponent_setproperty(field, property, value)
    DEFINE field, property, value STRING
    DEFINE wc, pd, pn om.DomNode
    DEFINE nl om.NodeList
    LET wc=webcomponent_findComponent(field)
    IF wc IS  NULL THEN RETURN END IF
    LET pd = wc.getFirstChild()
    IF pd IS NULL THEN 
      LET pd=wc.createChild("PropertyDict")
    END IF
    LET nl = pd.selectByPath(SFMT("//Property[@name=\"%1\"]",property))
    IF nl.getLength() = 1 THEN
      LET pn = nl.item(1)
    ELSE
      LET pn=pd.createChild("Property")
      CALL pn.setAttribute("name", property)
    END IF
    CALL pn.setAttribute("value", value)
END FUNCTION
