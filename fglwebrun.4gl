OPTIONS SHORT CIRCUIT
IMPORT util
IMPORT os
DEFINE m_gasdir STRING
DEFINE m_gasversion FLOAT
DEFINE m_fgldir STRING
DEFINE m_port INT
DEFINE m_isMac BOOLEAN
DEFINE m_gbcdir,m_gbcname STRING
DEFINE m_appname STRING
DEFINE m_GDC STRING
DEFINE m_html5 STRING
DEFINE m_appdata_dir STRING
DEFINE m_gashost STRING
DEFINE m_mydir STRING
DEFINE m_isGBC0 BOOLEAN --checks if we use the GBC prototype
--provides a simple command line fglrun replacement for GBC aka GWC-JS to do
--the same as 
-- % fglrun test a b c
--
--instead call on Unix
-- % FGLASDIR=<GASDIR> fglwebrun test a b c
--Windows
-- % set FGLASDIR=<GASDIR>&&fglwebrun test a b c
--for overriding the default system browser just set BROWSER in the env
-- % BROWSER=<Path_to_Chrome>/Chrome fglwebrun test
--
--for GDC Unix
-- % FGLASDIR=<GASDIR> GDC=<GDCEXECUTABLE> fglwebrun test a b c
--for GDC Windows
-- % set FGLASDIR=<GASDIR>&&set GDC=c:\progra~1\FourJs\gdc\bin\gdc.exe&&fglwebrun test a b c

MAIN
  LET m_port=6395 --default GAS port is 6394
  CALL setupVariables()
  IF num_args()<1 THEN
    DISPLAY sfmt("usage:%1 <program> <arg> <arg>",arg_val(0))
    RETURN
  END IF
  CALL checkGBCDir()
  IF NOT try_GASalive() THEN
    CALL runGAS()
  END IF
  IF m_gasversion<3.0 THEN
    CALL checkWebComponentInstall()
  END IF
  CALL createGASApp()
  IF m_GDC IS NOT NULL THEN
    CALL openGDC()
  ELSE
    IF fgl_getenv("GMI") IS NOT NULL THEN
      CALL connectToGMI()
    ELSE
      CALL openBrowser()
    END IF 
  END IF
END MAIN

FUNCTION setupVariables()
  LET m_gasdir=fgl_getenv("FGLASDIR")
  LET m_fgldir=fgl_getenv("FGLDIR")
  LET m_GDC=fgl_getenv("GDC")
  LET m_html5=fgl_getenv("HTML5")
  LET m_gashost=fgl_getenv("GASHOST")
  IF m_gashost IS NULL THEN
    LET m_gashost="localhost"
  END IF
  LET m_mydir=os.Path.fullPath(os.Path.dirname(arg_val(0)))
  LET m_isMac=NULL
  IF m_gasdir IS NULL THEN
    CALL myerr("FGLASDIR not set")
  END IF
  LET m_gasversion=getGASVersion()
END FUNCTION

--2.41 has no os.Path.fullPath
FUNCTION fullPath(dir_or_file)
  DEFINE oldpath,dir_or_file,full,baseName STRING
  DEFINE dummy INT
  LET full=dir_or_file
  LET oldpath=os.Path.pwd()
  IF NOT os.Path.exists(dir_or_file) THEN
    CALL myerr(sfmt("fullPath:'%1' does not exist",dir_or_file))
  END IF
  IF NOT os.Path.isDirectory(dir_or_file) THEN
    --file case
    LET baseName=os.Path.basename(dir_or_file)
    LET dir_or_file=os.Path.dirName(dir_or_file)
  END IF
  IF os.Path.chdir(dir_or_file) THEN
    LET full=os.Path.pwd()
    IF baseName IS NOT NULL THEN 
      --file case
      LET full=os.Path.join(full,baseName)
    END IF
  END IF
  CALL os.Path.chdir(oldpath) RETURNING dummy
  RETURN full
END FUNCTION

--if GBCDIR is set a custom GBC installation is linked into the GAS
--web dir
FUNCTION checkGBCDir()
  DEFINE dummy INT
  DEFINE custom_gbc,indexhtml STRING
  LET m_gbcdir=fgl_getenv("FGLGBCDIR")
  IF m_gbcdir IS NULL THEN
    LET m_gbcdir=fgl_getenv("GBCDIR")
    IF m_gbcdir IS NULL THEN
      RETURN
    END IF
  END IF
  IF (NOT os.Path.exists(m_gbcdir)) OR 
     (NOT os.Path.isDirectory(m_gbcdir)) THEN
    CALL myerr(sfmt("(FGL)GBCDIR %1 is not a directory",m_gbcdir))
  END IF
  LET m_gbcdir=fullPath(m_gbcdir);
  LET m_gbcname=os.Path.baseName(m_gbcdir);
  IF m_gbcname IS NULL THEN
    CALL myerr("GBC dirname must not be NULL")
  END IF
  IF m_gbcname=="gwc-js" THEN
    CALL myerr("GBC dirname must not be 'gwc-js'")
  END IF
  LET indexhtml=os.Path.join(m_gbcdir,"index.html")
  IF NOT os.Path.exists(indexhtml) THEN
    CALL myerr(sfmt("No index.html found in %1",m_gbcdir))
  END IF
  LET custom_gbc=os.Path.join(os.Path.join(m_gasdir,"web"),m_gbcname)
  LET m_isGBC0=os.Path.exists(os.Path.join(m_gbcdir,"gbc0.css"))
  --the linking into FGLASDIR/web is only required for the URL <gbcname>/index.html
  --we would not need to do it for /ua/r/_app links, but /ua/r/_app links
  --require a bootstrap.html
  --remove the old symbolic link
  CALL os.Path.delete(custom_gbc) RETURNING dummy
  CALL log(sfmt("custom_gbc:%1",custom_gbc))
  CALL mklink(m_gbcdir,custom_gbc,"could not link GBC into GAS web dir")
END FUNCTION

FUNCTION isWin()
  RETURN fgl_getenv("WINDIR") IS NOT NULL
END FUNCTION

FUNCTION mklink(src,dest,err)
  DEFINE src,dest,err STRING
  DEFINE code INT
  IF NOT isWin() IS NULL THEN
    RUN sfmt("ln -s %1 %2",src,dest) RETURNING code
  ELSE
    RUN sfmt("mklink %1 %2",src,dest) RETURNING code
  END IF
  IF code THEN
    CALL myerr(err)
  END IF
END FUNCTION

FUNCTION isMacInt()
  DEFINE arr DYNAMIC ARRAY OF STRING
  IF NOT isWin() THEN
    CALL file_get_output("uname",arr) 
    IF arr.getLength()<1 THEN 
      RETURN FALSE
    END IF
    IF arr[1]=="Darwin" THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

FUNCTION isMac()
  IF m_isMac IS NULL THEN 
    LET m_isMac=isMacInt()
  END IF
  RETURN m_isMac
END FUNCTION

FUNCTION file_get_output(program,arr)
  DEFINE program,linestr STRING
  DEFINE arr DYNAMIC ARRAY OF STRING
  DEFINE mystatus,idx INTEGER
  DEFINE c base.Channel
  LET c = base.channel.create()
  WHENEVER ERROR CONTINUE
  CALL c.openpipe(program,"r")
  LET mystatus=status
  WHENEVER ERROR STOP
  IF mystatus THEN
    CALL myerr(sfmt("program:%1, error:%2",program,err_get(mystatus)))
  END IF
  CALL arr.clear()
  WHILE (linestr:=c.readline()) IS NOT NULL
    LET idx=idx+1
    LET arr[idx]=linestr
  END WHILE
  CALL c.close()
END FUNCTION

FUNCTION quote(path)
  DEFINE path STRING
  IF path.getIndexOf(" ",1)>0 THEN
    LET path='"',path,'"'
  END IF
  RETURN path
END FUNCTION

FUNCTION getGASVersion()
  DEFINE ch base.channel
  DEFINE cmd,line,httpdispatch,vstring STRING
  DEFINE arr DYNAMIC ARRAY OF STRING
  DEFINE gasversion FLOAT
  DEFINE idx,i INT
 
  LET httpdispatch=getGASExe()
  LET ch = base.channel.create()
  LET cmd=quote(httpdispatch)," -V"
  --DISPLAY "gasversion cmd:",cmd
  CALL file_get_output(cmd,arr)
  LET gasversion=1.0
  FOR i=1 TO arr.getLength()
    LET line=arr[i]
    --DISPLAY sfmt("gasline(%1)=%2",i,line)
    #New format for httpdispatch -V (GAS 2.30)
    LET idx=line.getIndexOf("ttpdispatch ",2)    
    IF idx=0 THEN
      LET idx=line.getIndexOf("ersion",2)
      IF idx <> 0 THEN
        LET vstring=line.subString(idx+7,line.getLength())
        EXIT FOR
      END IF
    ELSE
      LET vstring=line.subString(idx+12,line.getLength())
      EXIT FOR
    END IF
  END FOR
  IF vstring IS NOT NULL THEN
    LET gasversion=parseVersion(vstring)
    DISPLAY "gasversion=",gasversion
  END IF
  CALL ch.close()
  RETURN gasversion
END FUNCTION

FUNCTION parseVersion(vstr)
  DEFINE vstr STRING
  DEFINE v,v2 STRING
  DEFINE fversion FLOAT
  DEFINE pointpos,prevpos INTEGER
  --cut out major.minor from the version
  LET pointpos=vstr.getIndexOf(".",1)
  IF pointpos>1 THEN
    LET v=vstr.subString(1,pointpos-1)
    LET prevpos=pointpos+1
  END IF
  --get the index of the 2nd point
  LET pointpos=vstr.getIndexOf(".",prevpos)
  IF pointpos>1 THEN
    LET v2=vstr.subString(prevpos,pointpos-1)
    LET v=v,".",v2
  END IF
  LET fversion=v
  RETURN fversion
END FUNCTION

FUNCTION getAppDir()
  RETURN os.Path.join(getAppDataDir(),"app")
END FUNCTION

FUNCTION getAppDataDir()
  DEFINE xcfdir STRING
  IF m_appdata_dir IS NULL THEN 
    LET m_appdata_dir=os.Path.join(os.Path.homeDir(),".gas_appdata")
    DISPLAY "m_appdata_dir:",m_appdata_dir
    LET xcfdir=os.Path.join(m_appdata_dir,"app")
    DISPLAY "xcfdir:",xcfdir
    IF NOT os.Path.exists(m_appdata_dir) THEN
      IF NOT os.Path.mkdir(m_appdata_dir) THEN
        CALL myerr(sfmt("Can't create appdata '%1'",m_appdata_dir))
      END IF
    ELSE
      IF NOT os.Path.isDirectory(m_appdata_dir) THEN
        CALL myerr(sfmt("'%1' is not a directory",m_appdata_dir))
      END IF
    END IF
    IF NOT os.Path.exists(xcfdir) THEN
      IF NOT os.Path.mkdir(xcfdir) THEN
        CALL myerr(sfmt("Can't create xcfdir '%1'",xcfdir))
      END IF
    ELSE
      IF NOT os.Path.isDirectory(xcfdir) THEN
        CALL myerr(sfmt("'%1' is not a directory",xcfdir))
      END IF
    END IF
  END IF
  RETURN m_appdata_dir
END FUNCTION

--write a GAS app entry 
FUNCTION createGASApp()
  DEFINE appfile,ext,cmd STRING
  DEFINE arg1 STRING
  DEFINE args DYNAMIC ARRAY OF STRING
  DEFINE code,i INT
  DEFINE invokeShell BOOLEAN
  LET arg1=arg_val(1)
  LET cmd= "fglrun -r ",arg1,IIF(isWin(),">NUL"," >/dev/null 2>&1")
  --we check if we can deassemble the file, this works for .42m and .42r
  RUN cmd RETURNING code
  IF code THEN --we could not find a valid .42r or .42m with the given argument
    LET invokeShell=TRUE
    IF isWin() THEN
      CALL myerr("not implemented:.bat invocation GAS") --need to ask Nico
    END IF
  END IF
  LET m_appname=os.Path.baseName(arg1)
  IF (ext:=os.Path.extension(m_appname)) IS NOT NULL THEN
    LET m_appname=m_appname.subString(1,IIF(ext.getLength()==0,m_appname.getLength(),m_appname.getLength()-ext.getLength()-1))
  END IF
  FOR i=2 TO num_args()
    LET args[i-1]=arg_val(i)
  END FOR
  LET appfile=os.Path.join(getAppDir(),sfmt("_%1.xcf",m_appname))
  CALL createXCF(appfile,arg1,args,invokeShell)
END FUNCTION

--create the XCF from a DomDocument
FUNCTION createXCF(appfile,module,args,invokeShell)
  DEFINE appfile, module STRING
  DEFINE args DYNAMIC ARRAY OF STRING
  DEFINE invokeShell BOOLEAN
  DEFINE copyenv DYNAMIC ARRAY OF STRING
  DEFINE i,eqIdx INT
  DEFINE line,name,basedir,wcdir,value STRING
  DEFINE doc om.DomDocument
  DEFINE root,exe,params,out,map,timeout om.DomNode
  LET doc=om.DomDocument.create("APPLICATION")
  LET root=doc.getDocumentElement()
  CALL root.setAttribute("Parent","defaultgwc")
  CALL root.setAttribute("xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance")
  CALL root.setAttribute("xsi:noNamespaceSchemaLocation","http://www.4js.com/ns/gas/2.30/cfextwa.xsd")
  IF invokeShell THEN
    CALL createResource(root,"res.dvm.wa","sh -c ")
  ELSE IF fgl_getenv("FGLRUN") IS NOT NULL THEN
    CALL createResource(root,"res.dvm.wa",fgl_getenv("FGLRUN"))
  END IF
  END IF
  IF fgl_getenv("FGLDIR") IS NOT NULL THEN
    CALL createResource(root,"res.fgldir",fgl_getenv("FGLDIR"))
  END IF
  CALL createResource(root,"res.path",fgl_getenv("PATH"))
  CALL createResource(root,"res.html5proxy.param","--development")
  LET exe=root.createChild("EXECUTION")
  --CALL exe.setAttribute("AllowUnsafeSession","TRUE")
  CALL file_get_output(IIF(isWin(),"set","env"),copyenv) 
  --we simply add every environment var in the .xcf file
  FOR i=1 TO copyenv.getLength() 
    LET line=copyenv[i]
    IF (eqIdx:=line.getIndexOf("=",1))>0 THEN
      LET name=line.subString(1,eqIdx-1) --may be we need to leave out some vars...candidate is _FGL_PPID
      IF name.getIndexOf("_FGL_",1)==1 or name.getIndexOf("FGLGUI",1)==1 THEN
        CONTINUE FOR
      END IF
      IF (value:=fgl_getenv(name)) IS NOT NULL THEN --check if we actually have this env
        CALL createEnv(exe,name,value)
      END IF
    END IF
  END FOR
  CALL createEnv(exe,"GAS_PUBLIC_DIR",getAppDataDir())
  CALL createTag(exe,"PATH",os.Path.pwd())
  CALL createTag(exe,"MODULE",module)
  LET params=exe.createChild("PARAMETERS")
  FOR i=1 TO args.getLength()
    CALL createTag(params,"PARAMETER",args[i])
  END FOR
  IF module.getCharAt(1)=="/" THEN --we were invoked via absolute path
    LET basedir=os.Path.dirname(module)
    LET wcdir=os.Path.join(basedir,"webcomponents")
    IF os.Path.exists(wcdir) THEN
      CALL log(sfmt("add <WEB_COMPONENT_DIRECTORY>:%1",wcdir))
      CALL createTag(exe,"WEB_COMPONENT_DIRECTORY",wcdir)
    END IF
  END IF
  CASE
    WHEN m_gasversion<3.0 OR m_html5 IS NOT NULL
      LET out=root.createChild("OUTPUT")
      LET map=out.createChild("MAP")
      CALL map.setAttribute("Id",sfmt("DUA_%1",IIF(m_gdc IS NOT NULL,"GDC","GWC")))
      CALL map.setAttribute("Allowed","TRUE")
    WHEN m_gbcdir IS NOT NULL
      LET out=root.createChild("UA_OUTPUT")
      CALL createTag(out,"PROXY","$(res.uaproxy.cmd)")
      CALL createTag(out,"PUBLIC_IMAGEPATH","$(res.public.resources)")
      IF m_gasversion>=3.1 THEN
        CALL createTag(out,"GBC",m_gbcname)
      ELSE
        CALL createTag(out,"GWC-JS",m_gbcname)
      END IF
      LET timeout=out.createChild("TIMEOUT")
      CALL createTag(timeout,       "USER_AGENT","20000")
      CALL createTag(timeout,       "REQUEST_RESULT","10000")
      IF m_isGBC0 THEN
        CALL cpHtmlAssets() 
      END IF
  END CASE
  TRY
    CALL root.writeXml(appfile)
    CALL log(sfmt("wrote gas app file:%1",appfile))
  CATCH
    CALL myerr(sfmt("Can't write %1:%2",appfile,err_get(status)))
  END TRY
END FUNCTION

FUNCTION getPublicDir()
  RETURN os.Path.join(getAppDataDir(),"public")
END FUNCTION

FUNCTION cpHtmlAssets()
  DEFINE public_gbcdir,public_fgldirlib,fgldirlib STRING
  --enumerate the .42f's and copy matching .html's to the GAS public dir
  --to protoype html forms
  DEFINE dh INT
  DEFINE fname,hname STRING
  LET dh=os.Path.dirOpen(os.Path.pwd())
    IF dh == 0 THEN
    RETURN
  END IF
  WHILE (fname:=os.Path.dirNext(dh)) IS NOT NULL
      IF fname IS NULL OR fname=="." OR 
        NVL(os.Path.extension(fname),"NULL")<>"42f" THEN
        CONTINUE WHILE
      END IF
      LET hname = fname.subString(1,fname.getLength()-3),"html"
      --DISPLAY "fname:",fname,",hname:",hname
      IF os.Path.exists(hname) THEN
        CALL cpHtmlAsset(hname)
      END IF
  END WHILE
  CALL os.Path.dirclose(dh)
  --link the 2 form2html resource dirs into public
  IF os.Path.exists("gbcdir") AND os.Path.isLink("gbcdir") THEN
    LET public_gbcdir=os.Path.join(getPublicDir(),"gbcdir")
    CALL os.Path.delete(public_gbcdir) RETURNING status
    CALL mklink(os.Path.fullPath("gbcdir"),public_gbcdir,"Can't link ./gbcdir into public")
  END IF
  IF os.Path.exists("fgldirlib") AND os.Path.isLink("fgldirlib") THEN
    LET public_fgldirlib=os.Path.join(getPublicDir(),"fgldirlib")
    CALL os.Path.delete(public_fgldirlib) RETURNING status
    LET fgldirlib=os.Path.join(base.Application.getFglDir(),"lib")
    CALL mklink(fgldirlib,public_fgldirlib,"Cant link $FGLDIR/lib into public")
  END IF
END FUNCTION

--load the html file and look for additional assets
--to copy
FUNCTION cpHtmlAsset(hname)
  DEFINE hname STRING
  DEFINE d om.DomDocument
  DEFINE r om.DomNode
  TRY
    LET d=om.DomDocument.createFromXmlFile(hname)
  CATCH
    DISPLAY "cpHtmlAsset: failed to read:",hname
    RETURN
  END TRY
  LET r=d.getDocumentElement()
  CALL searchHtmlAssets(r,"link","href")
  CALL searchHtmlAssets(r,"script","src")
  CALL cp2Public(os.Path.baseName(hname))
END FUNCTION

FUNCTION searchHtmlAssets(r,what,srcAttr)
  DEFINE r om.DomNode
  DEFINE what,srcAttr,src STRING
  DEFINE l om.NodeList
  DEFINE ass om.DomNode
  DEFINE i,questpos INT
  LET l=r.selectByTagName(what)
  FOR i=1 TO l.getLength()
    LET ass=l.item(i)
    LET src=ass.getAttribute(srcAttr)
    IF src IS NOT NULL THEN
      LET questpos=src.getIndexOf("?",1) --internal error when base.getIndexOf
      IF questpos>0 THEN
        LET src=src.subString(1,questpos-1)
      END IF
      IF os.Path.exists(src) THEN
        CALL cp2Public(src)
      END IF
    END IF
  END FOR
END FUNCTION

--copies an html asset to the GAS public dir
--this has the effect that the assets are cached
FUNCTION cp2Public(src)
  DEFINE src,dest STRING
  IF NVL(os.Path.dirname(src),"NULL")!="." THEN
    DISPLAY "copy2Public:do not copy asset not in pwd:",src
    RETURN
  END IF
  LET dest=os.Path.join(getPublicDir(),src)
  IF os.Path.exists(dest) AND file_equal(src,dest,FALSE) THEN
    DISPLAY sfmt("cp2Public: htmlAsset '%1' already copied",src)
    RETURN
  END IF
  IF NOT os.Path.copy(src,dest) THEN
    DISPLAY sfmt("cp2Public: can't copy htmlAsset '%1' to '%2'",src,dest)
  END IF
END FUNCTION

FUNCTION createContent(parent,content)
  DEFINE parent,chars om.DomNode
  DEFINE content STRING
  LET chars=parent.createChild("@chars")
  CALL chars.setAttribute("@chars",content)
END FUNCTION

FUNCTION createResource(parent,resId,content)
  DEFINE parent,res om.DomNode
  DEFINE resId,content STRING
  LET res=parent.createChild("RESOURCE")
  CALL res.setAttribute("Id",resId)
  CALL res.setAttribute("Source","INTERNAL")
  CALL createContent(res,content)
  --  CALL ch.writeLine(     "<RESOURCE Id=\"res.dvm.wa\" Source=\"INTERNAL\">sh -c </RESOURCE>")
END FUNCTION

FUNCTION createEnv(parent,varname,content)
  DEFINE parent,env om.DomNode
  DEFINE varname,content STRING
  LET env=parent.createChild("ENVIRONMENT_VARIABLE")
  CALL env.setAttribute("Id",varname)
  CALL createContent(env,content)
  --  CALL ch.writeLine( "    <ENVIRONMENT_VARIABLE Id=\"FGLGUI\">2</ENVIRONMENT_VARIABLE>")
END FUNCTION

FUNCTION createTag(parent,tagName,content)
  DEFINE parent,n om.DomNode
  DEFINE tagName,content STRING
  LET n=parent.createChild(tagName)
  CALL createContent(n,content)
END FUNCTION

FUNCTION getGASExe()
  DEFINE gasbindir,httpdispatch STRING
  LET gasbindir=os.Path.join(m_gasdir,"bin")
  LET httpdispatch=IIF(isWin(),"httpdispatch.exe","httpdispatch")
  LET httpdispatch=os.Path.join(gasbindir,httpdispatch)
  IF NOT os.Path.exists(httpdispatch) THEN
    CALL myerr(sfmt("Can't find %1",httpdispatch))
  END IF
  RETURN httpdispatch
END FUNCTION

FUNCTION runGAS()
  DEFINE cmd,httpdispatch,filter STRING
  DEFINE trial,i INT
  DEFINE redirect_error INT
  LET httpdispatch=getGASExe()
  IF isWin() THEN
    LET cmd='cd ',m_gasdir,'&&start ',httpdispatch
  ELSE
    --LET cmd="sudo dtruss ",httpdispatch
    LET cmd=httpdispatch
  END IF
  FOR trial=1 TO 4
    --LET filter="ERROR"
    --LET filter="ERROR PROCESS"
    IF (filter:=fgl_getenv("FILTER")) IS NULL THEN
      --default filter value
      --other possible values "ERROR" "ALL"
      LET filter="PROCESS"
    END IF
    LET cmd=cmd,' -p ', m_gasdir,sfmt(' -E "res.ic.port.offset=%1"',m_port-6300),' -E "res.log.output.type=CONSOLE" -E ',sfmt('"res.log.categories_filter=%1"',filter)
    --comment the following line if you want  to disable AUI tree watching
    LET cmd=cmd,'  -E res.uaproxy.param=--development '
    IF NOT isWin() THEN
      LET cmd=cmd,' -E "res.log.output.path=/tmp"'
    END IF
    IF m_gbcdir IS NOT NULL THEN
      LET cmd=cmd,
        --hooray, renamed options ... , since 3.10 "res.path.gbc.user"
        sfmt(' -E "res.path.%1.user=',IIF(m_gasversion>=3.1,"gbc","gwcjs")),
        os.Path.dirname(m_gbcdir),'"'
    END IF
    IF m_gasversion < 2.50 THEN
      LET cmd=cmd,' -E "res.path.app=',getAppDir(),'"'
    ELSE
      --renamed in 2.50...
      LET cmd=cmd,' -E "res.appdata.path=',getAppDataDir(),'"'
    END IF
    IF redirect_error THEN
      LET cmd=cmd," 2>",IIF(isWin(),"nul","/dev/null")
    END IF
    
    CALL log(sfmt("RUN %1 ...",cmd))
    RUN cmd WITHOUT WAITING
    FOR i=1 TO 360 
      IF try_GASalive() THEN
        RETURN
      END IF
      SLEEP 1
    END FOR
    LET m_port=m_port+1
  END FOR
  CALL myerr("Can't startup GAS, check your configuration, FGLASDIR")
END FUNCTION

FUNCTION try_GASalive()
    DEFINE c base.Channel
    DEFINE s STRING
    DEFINE found BOOLEAN
    LET c = base.Channel.create()
    CALL log(sfmt("probe GAS on port:%1...",m_port))
    TRY 
        CALL c.openClientSocket("127.0.0.1", m_port, "u", 1)
    CATCH
        CALL log(sfmt("GAS probe failed:%1",err_get(status)))
        RETURN FALSE
    END TRY
    CALL log("GAS probe ok")
    -- write header
    LET s = "GET /index.html HTTP/1.1"
    CALL writeLine(c, s)
    CALL writeLine(c, "Host: localhost")
    CALL writeLine(c, "User-Agent: fglrun")
    CALL writeLine(c, "Accept: */*")
    CALL writeLine(c, "Connection: close")
    CALL writeLine(c, "")

    LET found = read_response(c)
    CALL c.close()
    RETURN found
END FUNCTION

FUNCTION read_response(c)
    DEFINE c base.Channel
    DEFINE s STRING
    WHILE NOT c.isEof()
      LET s = c.readLine()
      CALL log(sfmt("GAS answer:%1",s))
      LET s = s.toLowerCase()
      IF (s MATCHES "server: gas/2*")
         OR (s MATCHES "x-fourjs-server: gas/3*") THEN
        RETURN TRUE
      END IF
      IF s.getLength() == 0 THEN
        EXIT WHILE
      END IF
    END WHILE
    RETURN FALSE
END FUNCTION

FUNCTION writeLine(c, s)
    DEFINE c base.Channel
    DEFINE s STRING
    LET s = s, '\r'
    CALL c.writeLine(s)
END FUNCTION

FUNCTION myerr(err)
  DEFINE err STRING
  DISPLAY "ERROR:",err
  EXIT PROGRAM 1
END FUNCTION

FUNCTION log(s)
  DEFINE s STRING
  IF fgl_getenv("VERBOSE") IS NOT NULL THEN
    DISPLAY "LOG:",s
  END IF
END FUNCTION

FUNCTION getTime()
  DEFINE data base.StringBuffer
  LET data = base.StringBuffer.create()
  CALL data.append(CURRENT)
  CALL data.replace(" ","_",0)
  CALL data.replace(":","_",0)
  RETURN data.toString()
END FUNCTION

FUNCTION openBrowser()
  DEFINE url,cmd,browser STRING
  DEFINE fglhost,host,fglwebrungdc,defgbc STRING
  LET fglhost=fgl_getenv("FGLCOMPUTER")
  LET host=IIF(fglhost IS NULL,"localhost",fglhost)
  CASE
    WHEN m_gasversion<3.0 OR m_html5 IS NOT NULL
      LET url=sfmt("http://%1:%2/wa/r/_%3?t=%4",host,m_port,m_appname,getTime())
    WHEN m_gbcdir IS NOT NULL
      LET url=sfmt("http://%1:%2/%3/index.html?app=_%4&t=%5",host,m_port,m_gbcname,m_appname,getTime())
    OTHERWISE
      --LET defgbc=IIF(m_gasversion>=3.2,"gbc","gwc-js")
      LET defgbc="gwc-js"
      LET url=sfmt("http://%1:%2/%3/index.html?app=_%3&t=%4",host,m_port,defgbc,m_appname,getTime())
  END CASE
  CALL log(sfmt("start GWC-JS URL:%1",url))
  LET browser=fgl_getenv("BROWSER")
  IF browser IS NOT NULL THEN
    CASE
    WHEN browser=="n" OR browser="no" OR browser=="none" 
      DISPLAY "Copy the following URL into your browser:"
      DISPLAY url
      RETURN
    WHEN browser=="gdc"
      LET fglwebrungdc=os.Path.join(fgl_getenv("FGLWEBRUNDIR"),"fglwebrungdc")
      LET cmd=sfmt('fglrun "%1" "%2"',fglwebrungdc,url)
      DISPLAY "cmd:",cmd
    OTHERWISE
      LET cmd=sfmt('"%1" %2',fgl_getenv("BROWSER"),url)
    END CASE
  ELSE
    CASE
      WHEN isWin() 
        LET cmd=sfmt("start %1",url)
      WHEN isMac() 
        LET cmd=sfmt('open "%1"',url)
      OTHERWISE --assume kinda linux
        LET cmd=sfmt("xdg-open %1",url)
    END CASE
  END IF
  CALL log(sfmt("browser cmd:%1",cmd))
  RUN cmd WITHOUT WAITING
END FUNCTION

FUNCTION getGASURL()
  RETURN sfmt("http://%1:%2/ua/r/_%3",m_gashost,m_port,os.Path.baseName(arg_val(1)))
END FUNCTION

FUNCTION connectToGMI()
  DEFINE cmd,result,fglserver STRING
  IF m_gashost IS NOT NULL THEN
    LET fglserver=fgl_getenv("GMIFGLSERVER")
    IF fglserver IS NULL THEN
      LET fglserver=fgl_getenv("FGLSERVER")
    END IF
    IF fglserver IS NULL THEN
      LET fglserver="localhost"
    END IF
    LET cmd=sfmt("FGLPROFILE=%1 FGLSERVER=%2 fglrun %3 %4",os.Path.join(m_mydir,"fglprofile"),fglserver,os.Path.join(m_mydir,"runonserver"),getGASURL())
    DISPLAY "RUN:",cmd
    RUN cmd WITHOUT WAITING
    RETURN
  END IF
  TRY
    CALL ui.Interface.frontCall("mobile","runOnServer",
          [getGASURL(),5],[result])
    CALL log(sfmt("runOnServer returned:%1",result))
  CATCH
    LET result=err_get(status)
    DISPLAY "ERROR:",result
  END TRY
END FUNCTION

FUNCTION openGDC()
  DEFINE gdc,cmd STRING
  LET gdc=m_gdc
  IF NOT os.Path.exists(gdc) THEN
    CALL myerr(sfmt("Can't find '%1'",gdc))
  END IF
  IF NOT os.Path.executable(gdc) THEN
    DISPLAY "Warning:os.Path not executable:",gdc
  END IF
  LET cmd=sfmt("'%1' -u %2",gdc,getGASURL())
  CALL log(sfmt("GDC cmd:%1",cmd))
  RUN cmd WITHOUT WAITING
END FUNCTION

#GAS <3.0
#installs webcomponents located in `pwd`/webcomponents/<component>
#into the GAS by copying them into $GASDIR/web/components/<component>
#For GAS >=3.00 this handled by GAS automatically
FUNCTION checkWebComponentInstall()
  DEFINE sub,html,component,webcomponents STRING
  DEFINE dirhandle INT
  LET webcomponents=os.Path.join(os.Path.pwd(),"webcomponents")
  IF os.Path.exists(webcomponents) AND os.Path.isDirectory(webcomponents) THEN
    LET dirhandle=os.Path.dirOpen(webcomponents)
    WHILE (component:=os.Path.dirNext(dirhandle)) IS NOT NULL
      IF component=="." OR component==".." THEN
        CONTINUE WHILE
      END IF
      LET sub=os.Path.join(webcomponents,component)
      LET html=os.Path.join(sub,component||".html")
      IF os.Path.exists(html) THEN
        CALL copyWCAssets(sub,component)
      END IF
    END WHILE
    CALL os.Path.dirClose(dirhandle)
  END IF
END FUNCTION

FUNCTION copyWCAssets(sub,component) 
  DEFINE sub,component STRING
  DEFINE name,componentsdir,componentdir,src,dest,webdir STRING
  DEFINE dirhandle,dummy INT
  #I did not figure out yet where the webcomponent can be made private to gas<3.0
  #so we pollute the GAS/web directory for now
  LET webdir=os.Path.join(m_gasdir,"web")
  IF NOT os.Path.exists(webdir) THEN
    IF NOT os.Path.mkdir(webdir) THEN
      CALL myerr(sfmt("Can't create '%1'",webdir))
    END IF
  ELSE 
    IF NOT os.Path.isDirectory(webdir) THEN
      CALL myerr(sfmt("'%1' is not a directory",webdir))
    END IF
  END IF
  LET componentsdir=os.Path.join(webdir,"components")
  IF NOT os.Path.exists(componentsdir) THEN
    IF NOT os.Path.mkdir(componentsdir) THEN
      CALL myerr(sfmt("Can't create web/components dir:%1",componentsdir))
    END IF
  END IF
  LET componentdir=os.Path.join(componentsdir,component)
  IF fgl_getenv("WINDIR") IS NULL THEN 
    RUN sfmt("rm -rf %1",componentdir) RETURNING dummy
  ELSE
    RUN sfmt("rmdir %1 /s /q",componentdir) RETURNING dummy
  END IF
  IF NOT os.Path.mkdir(componentdir) THEN
    CALL myerr(sfmt("Can't create webcomponent dir:%1",componentdir))
  END IF
  LET dirhandle=os.Path.dirOpen(sub)
  WHILE (name:=os.Path.dirNext(dirhandle)) IS NOT NULL
    IF name=="." OR name==".." THEN
      CONTINUE WHILE
    END IF
    LET src=os.Path.join(sub,name)
    LET dest=os.Path.join(componentdir,name)
    DISPLAY sfmt("copy '%1' -> '%2'",src,dest)
    IF NOT os.Path.copy(src,dest) THEN
      CALL myerr(sfmt("Can't copy '%1' to '%2'",src,dest))
    END IF
  END WHILE
  CALL os.Path.dirClose(dirhandle)
END FUNCTION

FUNCTION file_equal(f1, f2, ignorecase)
  DEFINE f1, f2 STRING
  DEFINE ignorecase BOOLEAN
  DEFINE cmd,opt STRING
  DEFINE code INTEGER
  LET opt = " "
  IF fgl_getenv("WINDIR") THEN
    IF ignorecase THEN
      LET opt = "/c"
    END IF
    LET cmd = "fc " || opt || " " || f1 || " " || f2
  ELSE
    IF ignorecase THEN
      LET opt = "-i"
    END IF
    LET cmd = "diff " || opt || " " || f1 || " " || f2
  END IF
  RUN cmd RETURNING code
  RETURN (code == 0)
END FUNCTION
