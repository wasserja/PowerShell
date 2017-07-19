'========================================
' File Exists
'========================================
'@INCLUDE=i18n/UTF8Decode.vbs

Option Explicit

Dim bExamineRemoteFolders ' boolean to decide whether to consider non-local dirs
bExamineRemoteFolders = True ' attempt to look at remote folders, may fail due to access

Dim strFilePath, objFso, objShell

strFilePath = UTF8Decode("||file||")

If InStr(LCase(strFilePath),"%userprofile%") > 0 Then
	CheckForAllUsers strFilePath
Else
	CheckNoUserVars strFilePath
End If

	
Sub CheckNoUserVars(ByVal strFilePath)
' plain check if a file exists
	strFilePath = FixFileSystemRedirectionForPath(strFilePath)
	Set objShell = CreateObject("WScript.Shell")
	
	strFilePath = objShell.ExpandEnvironmentStrings( strFilePath )
	
	Set objFso = WScript.CreateObject("Scripting.Filesystemobject")
	
	If objFso.FileExists(strFilePath) Then 
		WScript.Echo "File Exists: " & UnFixFileSystemRedirectionForPath(strFilePath)
	Else 
		WScript.Echo "File does not exist"
	End If
End Sub 'CheckNoUserVars

Sub CheckForAllUsers(ByVal strFilePath)
' checks in every user directory

	' Remove %userprofile% and keep the rest
	strFilePath = Replace(LCase(strFilePath),"%userprofile%","")	
	
	On Error Resume Next ' permissions issues, perhaps
	
	Const HKLM = &H80000002
	Dim objShell,objFso
	Dim objRegistry,strKeyPath,objSubKey,arrSubKeys,strValueName,strSubPath
	Dim strValue,strOut,bFileFound
	bFileFound = False
	Set objShell = CreateObject("WScript.Shell")
	
	strFilePath = objShell.ExpandEnvironmentStrings( strFilePath )
	
	Set objFso = WScript.CreateObject("Scripting.Filesystemobject")
	
	Set objRegistry=Getx64RegistryProvider
 
	strKeyPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
	objRegistry.EnumKey HKLM, strKeyPath, arrSubkeys
 

	For Each objSubkey In arrSubkeys
	    strValueName = "ProfileImagePath"
	    strSubPath = strKeyPath & "\" & objSubkey
	    objRegistry.GetExpandedStringValue HKLM,strSubPath,strValueName,strValue

	    If Not bExamineRemoteFolders And Not InStr(strValue,":") > 0 Then ' Not Local, don't get size of remote dirs
	    	' if user profile is not local and not examining remote profiles, ignore
	    Else 
	    	If objFSO.FileExists(strValue&strFilePath) Then
				bFileFound = True
				WScript.Echo "File Exists: " & strValue&strFilePath
			End If
		End If
	Next
	
	If Not bFileFound Then

		WScript.Echo "File does not exist"
	End If

	On Error Goto 0

End Sub 'CheckForAllUsers

Function Getx64RegistryProvider
    ' Returns the best available registry provider:  32 bit on 32 bit systems, 64 bit on 64 bit systems
    Dim objWMIService, colItems, objItem, iArchType, objCtx, objLocator, objServices, objRegProv
    Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
    Set colItems = objWMIService.ExecQuery("Select SystemType from Win32_ComputerSystem")    
    For Each objItem In colItems
        If InStr(LCase(objItem.SystemType), "x64") > 0 Then
            iArchType = 64
        Else
            iArchType = 32
        End If
    Next
    
    Set objCtx = CreateObject("WbemScripting.SWbemNamedValueSet")
    objCtx.Add "__ProviderArchitecture", iArchType
    Set objLocator = CreateObject("Wbemscripting.SWbemLocator")
    Set objServices = objLocator.ConnectServer("","root\default","","",,,,objCtx)
    Set objRegProv = objServices.Get("StdRegProv")   
    
    Set Getx64RegistryProvider = objRegProv
End Function ' Getx64RegistryProvider

Function FixFileSystemRedirectionForPath(strFilePath)
' This function will fix a folder location so that
' a 32-bit program can be passed the windows\system32 directory
' as a parameter.
' Even if the sensor or action runs in 64-bit mode, a 32-bit
' program called in a 64-bit environment cannot access
' the system32 directory - it would be redirected to syswow64.
' you would not want to do this for 64-bit programs.
	
	Dim objFSO, strSystem32Location,objShell
	Dim strProgramFilesx86,strNewSystem32Location,strRestOfPath
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	Set objShell = CreateObject("Wscript.Shell")

	strProgramFilesx86=objShell.ExpandEnvironmentStrings("%ProgramFiles%")

	strFilePath = LCase(strFilePath)
	strSystem32Location = LCase(objFSO.GetSpecialFolder(1))
	strProgramFilesx86=objShell.ExpandEnvironmentStrings("%ProgramFiles(x86)%")
	
	If objFSO.FolderExists(strProgramFilesx86) Then ' quick check for x64
		If InStr(strFilePath,strSystem32Location) = 1 Then
			strRestOfPath = Replace(strFilePath,strSystem32Location,"")
			strNewSystem32Location = Replace(strSystem32Location,"system32","sysnative")
			strFilePath = strNewSystem32Location&strRestOfPath
		End If
	End If
	FixFileSystemRedirectionForPath = strFilePath
	
	'Cleanup
	Set objFSO = Nothing
End Function 'FixFileSystemRedirectionForPath

Function UnFixFileSystemRedirectionForPath(strFilePath)
' This function will undo the changes made to a path by the 
' FixFileSystemRedirectionForPath function
' if a path is passed in with the sysnative string in it
' it will simply change it to system32, regardless of whether
' the OS is 64-bit.  A path will only be changed when it's
' necessary, so this has no effect when it's not changed.

	Dim objFSO,strSystem32Location,strNewSystem32Location
	
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	
	strFilePath = LCase(strFilePath)
	strSystem32Location = LCase(objFSO.GetSpecialFolder(1))
	strNewSystem32Location = Replace(strSystem32Location,"system32","sysnative")
	
	UnFixFileSystemRedirectionForPath = Replace(strFilePath,strNewSystem32Location,strSystem32Location)
	
	'Cleanup
	Set objFSO = Nothing
End Function 'UnFixFileSystemRedirectionForPath
'------------ INCLUDES after this line. Do not edit past this point -----
'- Begin file: i18n/UTF8Decode.vbs
'========================================
' UTF8Decode
'========================================
' Used to convert the UTF-8 style parameters passed from 
' the server to sensors in sensor parameters.
' This function should be used to safely pass non english input to sensors.
'-----
'-----
Function UTF8Decode(str)
    Dim arraylist(), strLen, i, sT, val, depth, sR
    Dim arraysize
    arraysize = 0
    strLen = Len(str)
    for i = 1 to strLen
        sT = mid(str, i, 1)
        if sT = "%" then
            if i + 2 <= strLen then
                Redim Preserve arraylist(arraysize + 1)
                arraylist(arraysize) = cbyte("&H" & mid(str, i + 1, 2))
                arraysize = arraysize + 1
                i = i + 2
            end if
        else
            Redim Preserve arraylist(arraysize + 1)
            arraylist(arraysize) = asc(sT)
            arraysize = arraysize + 1
        end if
    next
    depth = 0
    for i = 0 to arraysize - 1
		Dim mybyte
        mybyte = arraylist(i)
        if mybyte and &h80 then
            if (mybyte and &h40) = 0 then
                if depth = 0 then
                    Err.Raise 5
                end if
                val = val * 2 ^ 6 + (mybyte and &h3f)
                depth = depth - 1
                if depth = 0 then
                    sR = sR & chrw(val)
                    val = 0
                end if
            elseif (mybyte and &h20) = 0 then
                if depth > 0 then Err.Raise 5
                val = mybyte and &h1f
                depth = 1
            elseif (mybyte and &h10) = 0 then
                if depth > 0 then Err.Raise 5
                val = mybyte and &h0f
                depth = 2
            else
                Err.Raise 5
            end if
        else
            if depth > 0 then Err.Raise 5
            sR = sR & chrw(mybyte)
        end if
    next
    if depth > 0 then Err.Raise 5
    UTF8Decode = sR
End Function
'- End file: i18n/UTF8Decode.vbs