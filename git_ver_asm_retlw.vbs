Option Explicit

Const VERSION_TABLE_LABEL = "GIT_VERSION_TABLE"
Const VERSION_TABLE_LOCATION = "07E0"

Const VERSION_TAG_LABEL = "GIT_VERSION_TAG"
Const VERSION_TAG_SIZE = 16

Const VERSION_REV_LABEL = "GIT_VERSION_REV"
Const VERSION_REV_SIZE = 16

Const OUTPUT_FILE = "version.inc"

Const CODE_SECTION = "ORG"

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
	
	Dim strGitCommand
	dim aryMsg
	If Not WhereIs_GitCommand(strGitCommand) Then
		
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
	
	
	Dim aryCmd:aryCmd=Array()
	
	push_back aryCmd, ShellQuote(strGitCommand)
	
	push_back aryCmd, "describe"
	push_back aryCmd, "--tags"
	push_back aryCmd, "--long"	
	push_back aryCmd, "--dirty=_X"
	push_back aryCmd, "--abbrev=7"
	push_back aryCmd, "--always"	
		
	Dim strCmd: strCmd=Join(aryCmd," ")
	
	Dim strVersion, oProcOut, oProc
	
	Set oProc=oShell.Exec(strCmd)
	If Err.Number<>0 Then Exit Sub
	On Error Goto 0	
		
	Set oProcOut=oProc.StdOut
	If Not oProcOut.AtEndOfStream Then strVersion = oProcOut.ReadLine() 	
	Set oProcOut=Nothing : oProc.Terminate: Set oProc=Nothing

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


