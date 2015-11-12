Option Explicit

Const DISPLAY_WIDTH = 16
Const HEADER_FILE = "version.h"
Const OUTPUT_FILE = "version.c"

Dim g_strGitCommand

Main

Sub Main
	
	Dim strGitCommand
	If Not WhereIs_GitCommand(g_strGitCommand) Then
		WScript.StdErr.WriteLine("ERROR: Can't find Git.exe. Git Extensions may not be installed yet.")
		WScript.StdErr.WriteLine("see http://sourceforge.net/projects/gitextensions/")
		WScript.Quit(2)
		Exit Sub
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
	
	Dim strLine1, strLine2, nLast
	nLast = InStrRev(strVersion,"-")
	If nLast=0 Then strLine1="No Version" Else strLine1=Left(strVersion,nLast-1)
	strLine2=Mid(strVersion,nLast+1)
	
	If Right(strLine1,2)="-0" Then strLine1=Left(strLine1,Len(strLine1)-2)
	If Left(strLine2,1)="g" Then strLine2=Mid(strLine2,2)
	
	If IsEmpty(strTimeStamp) Then
		strLine2="rev:" & strLine2
	Else
		strLine2="X: " & strLine2
	End If
	
	If Len(strLine1)<DISPLAY_WIDTH Then  strLine1=String((DISPLAY_WIDTH-Len(strLine1))\2," ") & strLine1
	If Len(strLine2)<DISPLAY_WIDTH Then  strLine2=String((DISPLAY_WIDTH-Len(strLine2))\2," ") & strLine2
	
	Dim aryContent, strContent, strNewContent
	
	push_back aryContent,"// This file is Generated automatically, (Do not Edit)"
	push_back aryContent,"#include <pic18.h>"
	push_back aryContent,""
	push_back aryContent,"#include """ & HEADER_FILE & """"
	push_back aryContent,""	
	push_back aryContent,"const char GIT_VERSION[]=""" & Escape_String_C(strLine1) & "\n" & Escape_String_C(strLine2) & "\n"";"
	
	strNewContent = Join(aryContent,vbCrLf)
	
	Dim strTag
	strTag = """" & OUTPUT_FILE & """ <- " & Trim(strLine1) & ", " & Trim(strLine2)
	
	If GetFileContent(OUTPUT_FILE,strContent) Then
		If strContent<>strNewContent Then
			WScript.StdErr.WriteLine("Updating " & strTag)
			SetFileContent OUTPUT_FILE, strNewContent
		Else
			WScript.StdErr.WriteLine("Checked (No Change) " &  strTag)
		End If
	Else
		WScript.StdErr.WriteLine("Writeing New " &  strTag)
		SetFileContent OUTPUT_FILE, strNewContent
	End If

End Sub

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