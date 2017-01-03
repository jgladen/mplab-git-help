Option Explicit

Const VERSION_TABLE_LABEL = "GIT_VERSION_TABLE"
Const VERSION_TABLE_LOCATION = "07E0"

Const VERSION_TAG_LABEL = "GIT_VERSION_TAG"
Const VERSION_TAG_SIZE = 16

Const VERSION_REV_LABEL = "GIT_VERSION_REV"
Const VERSION_REV_SIZE = 16

Const OUTPUT_FILE = "version.inc"

Const CODE_SECTION = "ORG"

Dim g_strGitCommand

Main

Sub FormatContent(aryContent, strTag, strRev)
	dim aryLine
	
	push_back aryContent, ";******************************************************************************"
	push_back aryContent, ";            This file is Generated automatically, (Do not Edit)"
	push_back aryContent, ";******************************************************************************"	
	push_back aryContent, ""
	
	
	
	push_back aryContent, VERSION_TABLE_LABEL & VbTab & CODE_SECTION & VbTab & "H'" & VERSION_TABLE_LOCATION & "'"

	push_back aryContent, ""
	push_back aryContent, ""
		
	push_back aryContent, VERSION_TAG_LABEL
	
	
	push_back aryContent, "; """ & strTag & """"
	push_back_data aryContent, strTag	
	
	
	push_back aryContent, ""
	push_back aryContent, ""	
	
	push_back aryContent, VERSION_REV_LABEL	
	
	push_back aryContent, "; """ & strRev & """"
	push_back_data aryContent, strRev	
	
End Sub


Sub Main	
	
	dim aryMsg
	If Not WhereIs_GitCommand(g_strGitCommand) Then
		
		aryMsg=array()
		push_back aryMsg, "ERROR: Can't find Git.exe. Git Extensions may not be installed yet."
		push_back aryMsg, "see http://sourceforge.net/projects/gitextensions/"		
		
		Select Case GetScriptEngine() 
		case VBSCRIPT_CONSOLE
			WScript.StdErr.WriteLine(Join(aryMsg, VbCrLf))
			WScript.Quit(2)
		Case VBSCRIPT_GUI
			Msgbox Join(aryMsg, VbCrLf), 0, WSCRIPT.ScriptName
			Exit Sub
		end select
	End If

	Dim oShell: Set oShell = WScript.CreateObject("Wscript.Shell")
	
	Dim fso : Set fso = WScript.CreateObject("Scripting.FileSystemObject")
	
	Dim strCdUp: strCdUp = Exec_Git_Line("rev-parse --show-cdup")
	
	Dim aryStatus: aryStatus = Exec_Git_List("status --porcelain -u .")
	
	Dim strStatus
	Dim strPath
	Dim oFile
	Dim dtLastModified
	For Each strStatus In aryStatus
		strPath = strCdUp & Mid(strStatus,4)
		strPath = Replace(strPath,"/","\")
		On Error Resume Next
		Set oFile = fso.GetFile(strPath)
		On Error Goto 0
		If Not oFile Is Nothing Then 
			If Not IsEmpty(dtLastModified) Then 				
				If dtLastModified < oFile.DateLastModified Then
					dtLastModified = oFile.DateLastModified
				End If
			Else
				dtLastModified = oFile.DateLastModified
			End If			
			'WScript.StdErr.WriteLine(strPath & " " & oFile.DateLastModified)
		End If
	Next
	
	Dim strTimeStamp
	If Not IsEmpty(dtLastModified) Then
		strTimeStamp = Right("000" & hex(Hour(dtLastModified)* 600 + Minute(dtLastModified)* 10 + Second(dtLastModified)\6),4)
		'WScript.StdErr.WriteLine("TimeStamp: " & strTimeStamp)
	End If
	
	Dim aryCmd:aryCmd=Array()
	
	Dim aryParam	
	aryParam=Array()	
	
	push_back aryParam, "describe"
	push_back aryParam, "--tags"
	push_back aryParam, "--long"	
	
	
	If IsEmpty(strTimeStamp) Then 
		push_back aryParam, "--dirty=_X"
	Else
		push_back aryParam, "--dirty=_" & strTimeStamp
	End If
	
	push_back aryParam, "--abbrev=7"
	push_back aryParam, "--always"
	
	Dim strVersion: strVersion = Exec_Git_Line(aryParam)

	Dim strVersionTag, strVersionRev, nLast
	nLast = InStrRev(strVersion,"-")
	If nLast=0 Then strVersionTag="No Tag" Else strVersionTag=Left(strVersion,nLast-1)
	strVersionRev=Mid(strVersion,nLast+1)
	
	If Right(strVersionTag,2)="-0" Then strVersionTag=Left(strVersionTag,Len(strVersionTag)-2)
	If Left(strVersionRev,1)="g" Then strVersionRev=Mid(strVersionRev,2)
		
	If Len(strVersionTag)<VERSION_TAG_SIZE Then  strVersionTag=left(strVersionTag & String(VERSION_TAG_SIZE," "),VERSION_TAG_SIZE)
	If Len(strVersionRev)<VERSION_REV_SIZE Then  strVersionRev=left(strVersionRev & String(VERSION_REV_SIZE," "),VERSION_REV_SIZE)
	
	Dim aryContent, strContent, strNewContent
	
	FormatContent aryContent,strVersionTag,strVersionRev
	
	strNewContent = Join(aryContent,vbCrLf)


	Dim strTag
	strTag = """" & OUTPUT_FILE & """ <- " & Trim(strVersionTag) & ", " & Trim(strVersionRev)

	aryMsg=array()	
	If GetFileContent(OUTPUT_FILE,strContent) Then
		If strContent<>strNewContent Then			
			SetFileContent OUTPUT_FILE, strNewContent
			push_back aryMsg, "Updated " & strTag
		Else
			push_back aryMsg, "Checked (No Change) " &  strTag
		End If
	Else
		SetFileContent OUTPUT_FILE, strNewContent
		push_back aryMsg, "Wrote New " &  strTag		
	End If
	
	Select Case GetScriptEngine() 
	case VBSCRIPT_CONSOLE
		WScript.StdErr.WriteLine(Join(aryMsg, VbCrLf))
	Case VBSCRIPT_GUI
		push_back aryMsg, ""
		push_back aryMsg, "Please use prebuild step: "
		push_back aryMsg, "  cscript /nologo " & WSCRIPT.ScriptName
		Msgbox Join(aryMsg, VbCrLf), 0, WSCRIPT.ScriptName
	end select

End Sub

Const VBSCRIPT_CONSOLE=3
Const VBSCRIPT_GUI=7
Function GetScriptEngine()
	GetScriptEngine = (Asc(Right(WScript.FullName,11)) Mod 8) 
End function


Function WhereIs_GitBinDir(strResultPath)
	Const HKEY_CURRENT_USER = &H80000001
	Const HKEY_LOCAL_MACHINE = &H80000002
	
	Dim fso
	Set fso = WScript.CreateObject("Scripting.FileSystemObject")	
	
	Dim oReg,strKeyPath,strValueName
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
	
	'HKEY_CURRENT_USER\Software\GitExtensions\GitExtensions
	
	strKeyPath = "Software\GitExtensions\GitExtensions\"
	strValueName = "gitbindir"
	
	oReg.GetStringValue HKEY_CURRENT_USER, strKeyPath, strValueName, strResultPath
	
	Set oReg = Nothing
	Set fso = Nothing
	
	WhereIs_GitBinDir = Not IsNull(strResultPath) 	
	
End Function

Function WhereIs_GitCommand(strResultPath)
	Const HKEY_CURRENT_USER = &H80000001
	Const HKEY_LOCAL_MACHINE = &H80000002

	if WhereIs_GitBinDir(strResultPath) then
		strResultPath = strResultPath & "git.exe" 
		WhereIs_GitCommand = true
		exit function
	end if
	
	Dim fso
	Set fso = WScript.CreateObject("Scripting.FileSystemObject")	
	
	Dim oReg,strKeyPath,strValueName
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
	
	'HKEY_CURRENT_USER\Software\GitExtensions\GitExtensions
	
	strKeyPath = "Software\GitExtensions\"
	strValueName = "gitcommand"
	
	oReg.GetStringValue HKEY_CURRENT_USER, strKeyPath, strValueName, strResultPath
	
	Set oReg = Nothing
	Set fso = Nothing
	
	WhereIs_GitCommand = Not IsNull(strResultPath) 	
	
End Function



Public Sub push_back(aryData, Element)
    Dim NewSize 
    Select Case VarType(aryData)
    Case vbNull, vbEmpty
        aryData = Array(Element)
    Case vbVariant, vbArray, vbVariant + vbArray
        NewSize = UBound(aryData) - LBound(aryData) + 1
        ReDim Preserve aryData(NewSize)
        aryData(NewSize) = Element
    Case Else
        aryData = Array(aryData, Element)
    End Select

End Sub


Public Function ShellQuote(strText)
	If InStr(CStr(strText)," ")>0 Or InStr(CStr(strText),"""")>0 Then
		ShellQuote = """" & Replace(CStr(strText),"""","""""") & """"
	Else
		ShellQuote = CStr(strText)
	End If
End Function


Function GetFileContent(strFileName,strContent)
	GetFileContent=False
	Dim oFileIn	
	Dim fso: Set fso= WScript.CreateObject("Scripting.Filesystemobject")
	On Error Resume Next
	Set oFileIn=fso.OpenTextFile(strFileName,1,False)
	If Err.Number<>0 Then Exit function
	On Error Goto 0
			
	If Not IsObject(oFileIn) Then Exit Function
	
	If oFileIn.AtEndOfStream Then					
		strContent=""		
	Else
		strContent=oFileIn.ReadAll
	End If
	
	oFileIn.Close
	oFileIn=Empty
	GetFileContent=True	
End Function

Function SetFileContent(strFileName,strContent)
	SetFileContent=False
	
	Dim oFileOut	
	Dim fso: Set fso= WScript.CreateObject("Scripting.Filesystemobject")
	
	On Error Resume Next
	Set oFileOut=fso.CreateTextFile(strFileName,True)	
	If Err.Number<>0 Then Exit function
	On Error Goto 0
	
	oFileOut.Write strContent
	oFileOut.Close
	oFileOut=Empty

	SetFileContent=True
End Function

Function Escape_String_C(strText)
	Dim strResult:strResult=CStr(strText)
	strResult=Replace(strResult,"\","\\")
	strResult=Replace(strResult,"""","\""")	
	Escape_String_C = strResult
End Function

Function Quoted_String_C(strText)
	Quoted_String_C = """" & Escape_String_C(strText) & """"
End Function


Sub push_back_data(aryContent,strData)

	Dim nChar, aryLine	
	aryLine=Array()	
	
	For nChar = 1 To Len(strData)
		push_back aryContent, VbTab & "RETLW" & vbTab & "H'" & FormatDataByte(Mid(strData,nChar,1)) & "'"
		
	Next
	
End Sub	

Function FormatDataByte(strChar)
	FormatDataByte=Right("0" & Hex(Asc(strChar)),2)
End Function


Function Exec_Git_Line(aryParam)
	Dim oShell: Set oShell = WScript.CreateObject("Wscript.Shell")
	
	Dim aryCmd: aryCmd=Array()	
	Dim strParam
	push_back aryCmd, ShellQuote(g_strGitCommand)
	
	Select Case VarType(aryParam)
    Case vbNull, vbEmpty
    Case vbVariant, vbArray, vbVariant + vbArray
	    For Each strParam In aryParam			
			push_back aryCmd, ShellQuote(strParam)
		Next
    Case Else
    	push_back aryCmd, CStr(aryParam)
    End Select

	Dim strCmd: strCmd=Join(aryCmd," ")

	Dim oProc: Set oProc=oShell.Exec(strCmd)
	If Err.Number<>0 Then Exit Function
	On Error Goto 0	
		
	Dim oProcOut: Set oProcOut=oProc.StdOut
	If Not oProcOut.AtEndOfStream Then Exec_Git_Line = oProcOut.ReadLine() Else Exec_Git_Line=""
	Set oProcOut=Nothing : oProc.Terminate: Set oProc=Nothing

	Set oShell = Nothing

End Function

Function Exec_Git_List(aryParam)
	Dim oShell: Set oShell = WScript.CreateObject("Wscript.Shell")
	
	Dim aryResult:aryResult=Array()	
	
	Dim aryCmd: aryCmd=Array()	
	Dim strParam
	push_back aryCmd, ShellQuote(g_strGitCommand)
	
	Select Case VarType(aryParam)
    Case vbNull, vbEmpty
    Case vbVariant, vbArray, vbVariant + vbArray
	    For Each strParam In aryParam			
			push_back aryCmd, ShellQuote(strParam)
		Next
    Case Else
    	push_back aryCmd, CStr(aryParam)
    End Select

	Dim strCmd: strCmd=Join(aryCmd," ")

	Dim oProc: Set oProc=oShell.Exec(strCmd)
	If Err.Number<>0 Then Exit Function
	On Error Goto 0	
		
	Dim oProcOut: Set oProcOut=oProc.StdOut
	While Not oProcOut.AtEndOfStream 
		push_back aryResult, oProcOut.ReadLine()
	Wend
	Set oProcOut=Nothing : oProc.Terminate: Set oProc=Nothing

	Set oShell = Nothing
	
	Exec_Git_List = aryResult

End Function
