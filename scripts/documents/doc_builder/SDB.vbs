' -------------------------------
' SDB.vbs
' Steppes Travel Document Builder
' by Nick Casey 2010-04-23
' -------------------------------

' Usage: [CScript | WScript] SDB.vbs <jobid>

' Required Files and Settings:
' 	SDB.INI in same folder as Script (or elsewhere in environment path)
'		Steppes database as specified in INI connection string
'		Template Path as specified in INI connection string
'		Document Path as specified in INI connection string
'		Image Path as specified in INI connection string
'		Signature Path as specified in INI connection string
'		Portrait Path as specified in INI connection string

' 	Job record in document_jobs table
'		id to identify job (specified in script argument)
'		document_template_id to identify template set up in document_templates 
'		parameter xml in the form
'			<job>			
'				<x_id>y</x_id>
'			</job>
' 		where x_id can be client_id, invoice_id, user_id, trip_id or voucher_id and y is an integer
' 		and any number of these tags can be specified

' Version Info
' 0.1 - Started project. Implemented DB connection, INI file, first list parsing
' 0.2 - Generalised Tag Building (ParseTags method)
' 0.3 - Added delete table if empty, added image insertion, added misc tag parser, moved querys to stored procedures, added and improved list methods, standardised code, added full error handling
' 0.4 - Improved error handling: closes Word if close error, fails and exits if Word closed (requires CheckError inside loops), reports image not found
' 0.5 - Removed array containing named lists and replaced with list_of_* wild card search. Fixed bug reporting errors when inserting images.
' 0.6 - Added checks for existence of folders. Changed ERROR output to WARNING for less severe errors. Saving document using file_name instead of name

Option Explicit 

' ---Global Constants---
Const wdNormalView				= 1
Const wdStory					= 6 
Const wdWithinTable				= 12
Const wdStartOfRangeRowNumber	= 13	
Const wdDoNotConfirmConversion	= False
Const wdReadOnly				= True
Const strIniFileName			= "sdb.ini"
Const strUnknown				= "*unknown*"
Const intImageBorder			= 12
Const ForReading				= 1

' --- If the document.document_type_id matches either of these then we must use strLetterTemplatePath instead of strTemplatePath (default)
'     WARNING: These must match settings in the document_types table!
Const DOC_TYPE_LETTER   = 8
Const DOC_TYPE_BROCHURE = 12

' For setting document WdBuiltInProperty values: (using document.BuiltInDocumentProperties)
Const wdPropertyTitle    = 1 
Const wdPropertyAuthor   = 3 
Const wdPropertyKeywords = 4 
Const wdPropertyComments = 5
Const wdPropertyCompany  = 21 


' ---Global Variables---
Dim objFSO 
Set objFSO = CreateObject("Scripting.FileSystemObject")

Dim objSqlConnection

Dim strJobId

Dim strConnectionString
Dim strTemplatePath
Dim strLetterTemplatePath
Dim strDocumentPath
Dim strImagePath
Dim strSignaturePath
Dim strPortraitPath

Dim strScriptFolder
Dim strTemplateFileName
Dim strDocumentFileName
Dim intDocumentTypeID
Dim strClientId
Dim strTripId
Dim strUserId
Dim strInvoiceId
Dim strVoucherId
Dim strBrochureId

Dim objWord
Dim objTemplate
Dim objDocument
Dim objSelection
Dim boolInitialWordPagination
Dim intInitialWordViewType
Dim blnDoneTemplateSaveAs
    blnDoneTemplateSaveAs = False

' ---IIf --

Function IIf(objExpression, objTruePart, objFalsePart)
	If objExpression = True Then
		If IsObject(objTruePart) Then
			Set IIf = objTruePart
		Else
			IIf = objTruePart
		End If
	Else
		If IsObject(objFalsePart) Then
			Set IIf = objFalsePart
		Else
			IIf = objFalsePart
		End If
	End If
End Function


' ---Progress reporting---
Sub ReportProgress(strDescription)

	Dim strFormattedDescription

	'Log progress to the database (without affecting the status_id field)
	On Error Resume Next
	If IsObject(objSqlConnection) Then
		strFormattedDescription = "'" & vbLf & Replace(strDescription, "'", "''") & "'"
		objSqlConnection.Execute "EXEC sp_document_update_job_status " & strJobId & ", null, " & strFormattedDescription
		If Err.Number <> 0 Then Wscript.Echo "#ERROR# Unable to update job record to report progress."
	End If
	Err.Clear
	
	Wscript.Echo strDescription
	' **TODO: place progress in the database?
	' **TODO: provide number to this routine to help monitor progress

End Sub

' ---Error Handling---
Function CheckError(strDescription, boolContinue)
	
	Dim strErrorReport
	Dim boolIsError
	Dim strSeverity

	boolIsError = False	
	If Err.Number <> 0 Then
		
		strSeverity = IIf( boolContinue, "WARNING", "ERROR" )
		
		strErrorReport = "*" & strSeverity & "* " & _
			CStr(strDescription) & ": " & _
			Replace(Replace( Err.Description ,Chr(13),""),Chr(10),"") & " (" & _
			CStr(Err.Source) & " " & _
			CStr(Err.Number) & ")"

		' Note: Some Err.Description can cause odd truncation or formatting of the strErrorReport in Wscript.Echo output.
		' To improve readability we duplicate output the strSeverity and strDescription text:
		' TODO: Find out why this happens. (Already tried replacing CR, LF, Tab, Quote without any success.)
		'Wscript.Echo "*" & strSeverity & "* " & strDescription
		'Wscript.Echo strErrorReport
		ReportProgress strErrorReport
		
		' **TODO: provide number to this routine to help monitor progress
		
		Err.Clear

		If Not boolContinue Then
		
			On Error Resume Next
			
			' No need to save document if we havn't yet managed to make a copy of the template:
			If blnDoneTemplateSaveAs Then objTemplate.Save
			
			' Close Word but do not use FinaliseDocument through risk of circular errors
			objTemplate.Close
			objWord.Quit
		
			UpdateJobStatus(2)   ' update job status to failed
			Wscript.Quit
		End If
		
		boolIsError = True
		
	End If
	
	CheckError = boolIsError
	
End Function


' ---Get the script arguments---
Sub GetScriptArguments

	Dim arguments, totalArguments
	
	On Error Resume Next
	
	' Get the jobId as the only argument to the script

	Set arguments = WScript.Arguments
	totalArguments = arguments.Count
	
	If totalArguments  < 1 then
	    WScript.Echo "Usage: [CScript | WScript] SDB.vbs <jobid>"
	    WScript.Quit
	Else
		strJobId = arguments.Item(0)
	End If
	
	CheckError "Unable to get script arguments", False
	
End Sub

' ---Get INI file settings---
Sub ReadIniFile

	Dim strIniFileContents 
	
    'On Error Resume Next
    
    ReportProgress("Getting INI file settings...")

	'If Not IsObject(objFSO) Or objFSO Is Nothing Then Err.Raise 414, "ReadIniFile", "Object required"
	'CheckError "Unable to proceed without a FileSystemObject", False

	' Open the INI file: (Derive current folder from script path)
	strScriptFolder    = Replace( WScript.ScriptFullName, WScript.ScriptName, "" )
	If Not objFSO.FileExists( strScriptFolder & strIniFileName ) Then Err.Raise 53, "ReadIniFile", "File not found"
	CheckError "Unable to locate INI file (" & strScriptFolder & strIniFileName & ")", False
	strIniFileContents = objFSO.OpenTextFile( strScriptFolder & strIniFileName, ForReading ).ReadAll
	CheckError "Unable to open INI file (" & strScriptFolder & strIniFileName & ")", False

	' Get keys
	strConnectionString		= GetIniFileKey(strIniFileContents, "ConnectionString")
	ReportProgress(" - connection string: " & IIf(strConnectionString = "", "n/a", strConnectionString))
	strTemplatePath			= GetIniFileKey(strIniFileContents, "TemplatePath")
	ReportProgress(" - template path: " & IIf(strTemplatePath = "", "n/a", strTemplatePath))
	strLetterTemplatePath	= GetIniFileKey(strIniFileContents, "LetterTemplatePath")
	ReportProgress(" - letter template path: " & IIf(strLetterTemplatePath = "", "n/a", strLetterTemplatePath))
	strDocumentPath			= GetIniFileKey(strIniFileContents, "DocumentPath")
	ReportProgress(" - document path: " & IIf(strDocumentPath = "", "n/a", strDocumentPath))
	strImagePath			= GetIniFileKey(strIniFileContents, "ImagePath")
	ReportProgress(" - image path: " & IIf(strImagePath = "", "n/a", strImagePath))
	strSignaturePath		= GetIniFileKey(strIniFileContents, "SignaturePath")
	ReportProgress(" - signature path: " & IIf(strSignaturePath = "", "n/a", strSignaturePath))
	strPortraitPath			= GetIniFileKey(strIniFileContents, "PortraitPath")
	ReportProgress(" - portrait path: " & IIf(strPortraitPath = "", "n/a", strPortraitPath))
	
	CheckError "Unable to get INI file settings", False
	
	ReportProgress("")
	
	'Bail-out if we hit a show-stopper:
	If Not objFSO.FolderExists(strTemplatePath)  Then Err.Raise 53, "ReadIniFile", "Template path is invalid " & strTemplatePath
	CheckError "Invalid INI file settings", False
	If Not objFSO.FolderExists(strLetterTemplatePath)  Then Err.Raise 53, "ReadIniFile", "Letter Template path is invalid " & strLetterTemplatePath
	CheckError "Invalid INI file settings", False
	If Not objFSO.FolderExists(strDocumentPath)  Then Err.Raise 53, "ReadIniFile", "Document path is invalid " & strDocumentPath
	CheckError "Invalid INI file settings", False

	'Report problems that could spoil the generated document:
	If Not objFSO.FolderExists(strImagePath)     Then Err.Raise 53, "ReadIniFile", "Image path is invalid " & strImagePath
	CheckError "Invalid INI file settings", True
	If Not objFSO.FolderExists(strPortraitPath)  Then Err.Raise 53, "ReadIniFile", "Portrait path is invalid " & strPortraitPath
	CheckError "Invalid INI file settings", True
	If Not objFSO.FolderExists(strSignaturePath) Then Err.Raise 53, "ReadIniFile", "Signature path is invalid " & strSignaturePath
	CheckError "Invalid INI file settings", True
	
End Sub

' --Get particular INI file key--
Function GetIniFileKey(strIniFileContents, strKeyName)

	On Error Resume Next

	Dim keyPosition 
	Dim startPosition
	Dim endPosition
	Dim strIniFileKeyValue
	
	strIniFileKeyValue = strUnknown

	' Read text between strKeyName and the end of the line
	keyPosition = InStr(1, strIniFileContents, vbCrLf & strKeyName & "=", vbTextCompare)

	If keyPosition > 0 Then
		startPosition = keyPosition + Len(vbCrLf & strKeyName & "=")
		endPosition = InStr(startPosition, strIniFileContents, vbCrLf)
	    strIniFileKeyValue= Mid(strIniFileContents, startPosition, endPosition - startPosition)
	End If
	
	If strIniFileKeyValue = strUnknown Then
		Err.Raise 10001
		Err.Description = "Cannot find INI file key " & strKeyName
		CheckError "Unable to get key " & strKeyName, False
	End If

	' Ensure any file path settings use back-slashes and not forward-slashes:
	If InStr(1, strIniFileKeyValue, "path", vbTextCompare) > 0 Then strIniFileKeyValue = Replace(strIniFileKeyValue, "/", "\" )
	
	GetIniFileKey = strIniFileKeyValue

End Function

' ---Open SQL connection---
Sub OpenSQLConnection

	On Error Resume Next
	
	ReportProgress("Connecting to database...")
	
	Set objSqlConnection = CreateObject("Adodb.Connection")
	objSqlConnection.Open strConnectionString
	CheckError "Unable to open SQL connection", False
	
End Sub

' ---Close SQL connection---
Sub CloseSqlConnection

	On Error Resume Next
	
	objSqlConnection.Close
	
	CheckError "Unable to close database connection", False

End Sub

' ---Update the job status with supplied status---
' 0 - pending, 1 - running, 2 - failed, 3 - success
Sub UpdateJobStatus(intStatus)

	On Error Resume Next

	ReportProgress("Updating job status to " & intStatus & "...")  

	objSqlConnection.Execute "Exec sp_document_update_job_status " & strJobId & ", " & intStatus
	CheckError "Unable to update job status", False

End Sub

' --- Helper for detecting TEST environment: (Used for debugging) ---
'     (Warning: Examines DB name so not very reliable!)
Function isTestEnvironment
	isTestEnvironment = InStr( 1, strConnectionString, "TEST", vbTextCompare )
End Function

' --- Helper for detecting DEV environment: (Used for debugging) ---
'     (Warning: Examines DB name so not very reliable!)
Function isDevEnvironment
	isDevEnvironment = InStr( 1, strConnectionString, "DEV", vbTextCompare )
End Function

' ---Get Job parameters from the database---
Sub GetJobParameters

	Dim objJobRecordSet
	Dim objJobFields
	Dim strChosenTemplatePath
	
	On Error Resume Next

	ReportProgress("Getting job parameters...")  
	
	' Run SQL to return the job parameters
	Set objJobRecordSet = CreateObject("Adodb.Recordset")
	Set objJobFields    = objJobRecordSet.Fields
	objJobRecordSet.Open "Exec sp_document_job_parameters " & strJobId, objSqlConnection
	CheckError "Unable to open job recordset", False
	
	If objJobRecordSet.EOF Then 
		Err.Raise 10002
		Err.Description = "Cannot find job record id " & strJobId
		CheckError "Cannot find job record", False
	Else
	
		' ** TODO: though it might want to be done in the script caller
		' Check the status and report rather than run if already running or if completed

		intDocumentTypeID	= objJobFields.Item("document_type_id")
		ReportProgress(" - document type id: " & IIf(objJobFields.Item("document_type_id") = "", "n/a", intDocumentTypeID ))    

		' Decide which template folder to look in:
		strChosenTemplatePath = IIf( intDocumentTypeID = DOC_TYPE_LETTER Or intDocumentTypeID = DOC_TYPE_BROCHURE, strLetterTemplatePath, strTemplatePath )

		' Derive full template path from strChosenTemplatePath and template_name (AKA document_template_file in database):
		strTemplateFileName = strChosenTemplatePath + "\" + objJobFields.Item("template_name")
		strTemplateFileName = Replace( strTemplateFileName, "/", "\" )
		ReportProgress(" - template file name: " & IIf(objJobFields.Item("template_name") = "", "n/a", strTemplateFileName ))    

		' Derive full doc path from path and filename: (Change any forward-slashes to back-slashes just in case)
		strDocumentFileName = strDocumentPath + "\" + objJobFields.Item("document_file_name")
		strDocumentFileName = Replace( strDocumentFileName, "/", "\" )
		ReportProgress(" - document file name: " & IIf(objJobFields.Item("document_file_name") = "", "n/a", strDocumentFileName))    

		strClientId			= objJobFields.Item("client_id")
		ReportProgress(" - client id: " & IIf(strClientId = "", "n/a", strClientId))    

		strTripId			= objJobFields.Item("trip_id")
		ReportProgress(" - trip id: " & IIf(strTripId = "", "n/a", strTripId))    

		strUserId			= objJobFields.Item("user_id")
		ReportProgress(" - user id: " & IIf(strUserId = "", "n/a", strUserId))    

		strInvoiceId		= objJobFields.Item("invoice_id")
		ReportProgress(" - invoice id: " & IIf(strInvoiceId = "", "n/a", strInvoiceId))    

		strVoucherId		= objJobFields.Item("voucher_id")
		ReportProgress(" - voucher id: " & IIf(strVoucherId = "", "n/a", strVoucherId))    

		strBrochureId		= objJobFields.Item("brochure_request_id")
		ReportProgress(" - brochure request id: " & IIf(strBrochureId = "", "n/a", strBrochureId))    

		CheckError "Unable to read job recordset data", False

	End If

	objJobRecordSet.Close()

	ReportProgress("")

End Sub

' ---End of Populate list functions---

' ---Create document by saving a copy of the template---
Sub InitialiseDocument

	ReportProgress "Initialising document..."
	
	On Error Resume Next

	' Create a Word object
	Set objWord = CreateObject("Word.Application")

	objWord.Visible = isTestEnvironment() Or isDevEnvironment()	'Visible when running unit tests.
	objWord.ScreenUpdating = False
	
	Dim strTemplateFolder
	
	If Not objFSO.FileExists(strTemplateFileName) Then Err.Raise 53, "OpenTemplateDoc", "Template File not found"
	CheckError "Unable to open template file (" + strTemplateFileName + ")", False
	
	' Open template read only:
	' Note: For some reason the Err.Description will contain a truncated copy of the path so not much help (eg "C:\...\tst_Letter_Brochure_Enquiry.doc")
	Set objTemplate = objWord.Documents.Open(strTemplateFileName, wdDoNotConfirmConversion, wdReadOnly)
	CheckError "Unable to open template", False

	' Save document immediately - get path root from ini - 'ainder of path presented as parameter
	objTemplate.SaveAs(strDocumentFileName & ".running")
	CheckError "Unable to save template as running document (" & strDocumentFileName & ")", False

	' Set document properties (Mostly as a precaution to override old values left there from old templates!)
	objTemplate.BuiltInDocumentProperties(wdPropertyTitle)    = "Steppes Travel document"
	objTemplate.BuiltInDocumentProperties(wdPropertyAuthor)   = "Steppes Travel"
	objTemplate.BuiltInDocumentProperties(wdPropertyCompany)  = "Steppes Travel"
	objTemplate.BuiltInDocumentProperties(wdPropertyKeywords) = "steppes travel document"
	objTemplate.BuiltInDocumentProperties(wdPropertyComments) = ""
	CheckError "Unable to customise document properties", True
	
	' Flag to let error handler know we're now working with a new copy of the document:
	blnDoneTemplateSaveAs = True

	' Replace various document settings for performance reasons		
	boolInitialWordPagination      = objWord.Options.Pagination 
	intInitialWordViewType         = objWord.ActiveWindow.View.Type
	objWord.Options.Pagination     = False
	objWord.ActiveWindow.View.Type = wdNormalView 
	CheckError "Unable to replace document settings", True
	
	' Create a global selection object
	Set objSelection = objWord.Selection
	
	CheckError "Unable to initialise document", False

End Sub

' --- Save the document with its final name ---
Sub FinaliseDocument

	ReportProgress "Finalising document..."
	
	On Error Resume Next

	' Restore the default settings
	objWord.Options.Pagination = boolInitialWordPagination 
	objWord.ActiveWindow.View.Type = intInitialWordViewType
	
	' Save as proper name
	objTemplate.SaveAs(strDocumentFileName) 'Note that this DOES NOT add doc if there isnt one in the job table field - not assuming that is what is wanted
	CheckError "Unable to save file as " & strDocumentFileName, False
	
	ReportProgress " - document saved as '" & strDocumentFileName & "'"
	
	' Close the template and quit Word
	objTemplate.Close
	objWord.Quit
	CheckError "Unable to close Word", True
	
	' Remove the running version
	objFSO.DeleteFile(strDocumentFileName & ".running")
	CheckError "Unable to delete file " & strDocumentFileName & ".running", True
	
End Sub


' --- Date Functions ---

Function PadDate(strDate, intDigits)

	On Error Resume Next

	If intDigits > Len(strDate) then 
		PadDate = String(intDigits - Len(strDate),"0") & strDate
	Else 
		PadDate = strDate
	End if 
	
	CheckError "Unable to pad date", True
	
End Function 

' --- Date format yyyy-mm-dd
Function GetSQLFriendlyDate(strDate)

	Dim strFormattedDate
	
	On Error Resume Next

	If Not IsNull(strDate) Then
	
		strFormattedDate = PadDate(Right(Year(strDate),4),2) & "-" & _ 
			PadDate(Month(strDate),2) & "-" & _ 
			PadDate(Day(strDate),2)
	End If
			
	GetSQLFriendlyDate = strFormattedDate
	
	CheckError "Unable to get SQL friendly date", True

End Function

' --- Date format dd/mm/yyyy
Function GetStandardDate(strDate)

	Dim strFormattedDate
	
	On Error Resume Next

	If Not IsNull(strDate) Then
	
		strFormattedDate = PadDate(Day(strDate),2) & "/" & _ 
			PadDate(Month(strDate),2) & "/" & _ 
			PadDate(Right(Year(strDate),4),2)
    
    End If
				
	GetStandardDate = strFormattedDate

	CheckError "Unable to get standard date", True
        
End Function

' --- Date format dddd dd mmm 
Function GetLongDate(strDate)

	Dim strFormattedDate
	
	On Error Resume Next

	If Not IsNull(strDate) Then
	
		strFormattedDate = WeekDayName(WeekDay(strDate)) & " " & _ 
			Day(strDate) & " " & _ 
			MonthName(Month(strDate)) 
        
    End If
				
	GetLongDate = strFormattedDate
	
	CheckError "Unable to get long date", True
        
End Function

' --- Date format dd mmm yyyy
Function GetFullDate(strDate)

	Dim strFormattedDate
	
	On Error Resume Next

	If Not IsNull(strDate) Then
	
		strFormattedDate = Day(strDate) & " " & _ 
			MonthName(Month(strDate)) & " " & _
			Right(Year(strDate),4) 
    
    End If
				
	GetFullDate = strFormattedDate
	
	CheckError "Unable to get full date", True
        
End Function

Function GetTime(strDate)

	Dim strFormattedDate
	
	On Error Resume Next

	If Not IsNull(strDate) Then
	
		strFormattedDate = PadDate(Hour(strDate), 2) & ":" & _ 
        PadDate(Minute(strDate), 2) 
        
   	End If
				
	GetTime = strFormattedDate
	
	CheckError "Unable to get time", True
        
End Function

' --- Check if table is marked for deletion if empty and delete it if it is empty
' Returns True if the table is deleted
Function CheckTableDelete(objRecordSet)

	Dim boolDeleted
	
	On Error Resume Next

	boolDeleted = False
	objSelection.SelectRow
	objSelection.Find.ClearFormatting
	objSelection.Find.MatchWildCards = False
	If objSelection.Find.Execute("{delete_table_if_empty}") Then
	
		If objRecordSet.EOF Then
	
			ReportProgress(" - no items in list: it will be deleted")
			objSelection.Tables(1).Delete
			CheckError "Unable to delete empty table", True
			boolDeleted = True

		Else
	
			objSelection.Text = "" ' Remove the {delete_table_if_empty} tag
		
		End If
	
	End If
	
	CheckTableDelete = boolDeleted
	
	CheckError "Unable to check table delete", False
	
End Function


' --- Insert image ---
Sub InsertImage(strImagePath, strImageFile)

	Dim strFullImagePath
	Dim objWordPicture
	Dim intInitialWidth
	
	On Error Resume Next
	
	If(Not strImageFile & "" = "") Then  'to captures nulls we concat & ""
	
		strFullImagePath = strImagePath & "\" & strImageFile

		If objFSO.FileExists(strFullImagePath) Then
			Set objWordPicture = objSelection.InlineShapes.AddPicture(strFullImagePath, False, True) 

			'size image to table cell
			If objSelection.Information(wdWithintable) Then

				'**TODO: consider if we do actually want to expand image if it is smaller than the cell

				'thought this would work adjust height if width was changed but I hope too much:			objWordPicture.LockAspectRatio  = True
				intInitialWidth = objWordPicture.Width
				objWordPicture.Width = objSelection.Cells(1).Width - intImageBorder
				objWordPicture.Height = objWordPicture.Height * (objWordPicture.Width / intInitialWidth)

			End If

		Else
			Err.Raise 10003
			Err.Description = "File does not exist"
			CheckError "Image file '" & strFullImagePath & "'does not exist", True
		End If
		
	End If

	CheckError "Unable to insert image", False

End Sub


' --- Find and Replace Fields---
' Go through the specified selection parsing all tags starting with the field type until there are none left
Sub FindAndReplaceFields(strTagType, objFields, boolIsList, boolIgnoreDateField)

	Dim strTagName
	Dim strFieldData
	
	On Error Resume Next
	
	' If is list then selection is set to the row for each search
	If boolIsList Then
		objSelection.SelectRow
	Else
	   	objSelection.HomeKey wdStory
	End If
	
	objSelection.Find.ClearFormatting
	objSelection.Find.MatchWildCards = true	
	
	'Do each field until it is not found any more
	Do Until objSelection.Find.Execute("\{" & strTagType & ".*\}") = False 'keep finding user fields until there are no more
		
		'replace the selection with the correct field from the table
		strTagName = Replace(Replace(objSelection.Text, "{" & strTagType & ".", ""), "}", "")
	
		' Special cases
		
		' Some of the tags in the document include a string for formatting
		' the formatting string must be removed to get the name of the data fields
		' Other fields need file names attached and the selection replaced with an image rather than text
		
		If Instr(strTagName, "portrait") > 0 Then

			strFieldData = ""
			InsertImage strPortraitPath, objFields.Item(strTagName & "_file")
			
		ElseIf Instr(strTagName, "image") > 0 Then

			strFieldData = ""
			InsertImage strImagePath, objFields.Item(strTagName & "_file")
		
		ElseIf Instr(strTagName, "signature") > 0 Then
				
			strFieldData = ""
			InsertImage strSignaturePath, objFields.Item(strTagName & "_file")
			
		ElseIf strTagName = "countries_and" _
					Or strTagName = "client_names_and" Then 'replace last comma with AND (cant do easily in SQL
			
			strFieldData = objFields.Item(Replace(strTagName, "_and", ""))
			strFieldData = Trim(StrReverse(Replace(StrReverse(strFieldData), ",", "dna ", 1, 1))) 'better than & in a letter

		ElseIf strTagName = "countries" _
					Or strTagName = "client_names" Then 'replace last comma with AND (cant do easily in SQL
			
			strFieldData = objFields.Item(strTagName)
			strFieldData = Trim(StrReverse(Replace(StrReverse(strFieldData), ",", "& ", 1, 1)))
				
		ElseIf InStr(strTagName, "_time") > 0 Then ' NOTE that _time tags are derived from _date fields
		
			strFieldData = objFields.Item(Replace(strTagName, "_time", "_date")) 
			strFieldData = GetTime(strFieldData)
			
		ElseIf InStr(strTagName, "_date_full") > 0 Then
		
			strFieldData = objFields.Item(Replace(strTagName, "_date_full", "_date")) 
			strFieldData = GetFullDate(strFieldData)
			
		ElseIf InStr(strTagName, "_date_long") > 0 Then
		
			strFieldData = objFields.Item(Replace(strTagName, "_date_long", "_date")) 
			strFieldData = GetLongDate(strFieldData)
			
		ElseIf InStr(strTagName, "_date") > 0 Then
	
			strFieldData = objFields.Item(strTagName)
			strFieldData = GetStandardDate(strFieldData)
			
		ElseIf InStr(strTagName, "net_") > 0 _
				Or InStr(strTagName, "_net") > 0 _ 
				Or InStr(strTagName, "cost_") > 0 _
				Or InStr(strTagName, "_cost") > 0 _
				Or InStr(strTagName, "price_") > 0 _
				Or InStr(strTagName, "_price") > 0 _
				Or InStr(strTagName, "gross_") > 0 _
				Or InStr(strTagName, "_gross") > 0 Then
		
			strFieldData = objFields.Item(strTagName)
			strFieldData = FormatNumber(strFieldData, 2)
		
		Else
		
			strFieldData = objFields.Item(strTagName)
			
		End If
		
		'hack to avoid repeating date field in itinerary lists
		If InStr(strTagName, "date") And boolIgnoreDateField Then
			strFieldData = ""
		End If

		If IsNull(strFieldData) Then
			strFieldData = ""
		End If
		
		If CheckError("Problem with field " & strTagType & "." & strTagName, (Err.Number = 3265)) Then 'if field not found in recordset, report but continue parsing
			strFieldData = "{*" & strTagType & "." & strTagName & " - NOT IN DATA*}"
		End If
		
		objSelection.Text = strFieldData

		' set the selection back to the relevant scope
		If boolIsList Then
			objSelection.SelectRow
		Else
			objSelection.HomeKey wdStory
		End If
		
		CheckError "Unable to find and replace fields of type " & strTagType, False

	Loop
	
	CheckError "Unable to find and replace fields of type " & strTagType, False
	

End Sub


' ---Populate list functions---

' ---Populates a list with the records returned by the specified procedure--
Sub PopulateTripList(strListName, strStoredProcedureName)

	Dim objRecordSet
	Dim objFields
	Dim objTable
	Dim intTemplateRowNumber
	Dim objTemplateRow
	Dim intNewRowNumber
	
	On Error Resume Next
	
	If(Not IsNumeric(strTripId)) Then
		
		ReportProgress(" - cannot build " & strListName & ": no trip id")
		
	Else

		ReportProgress(" - building " & strListName)
		
		' Get the recordset of daily activities for the trip
		Set objRecordSet = CreateObject("Adodb.Recordset")
		Set objFields = objRecordSet.Fields
		objRecordSet.Open "EXEC " & strStoredProcedureName & " " & strTripId, objSqlConnection

		If Not CheckTableDelete(objRecordSet) Then
					
			' Initialise the table row copy mechanism
			Set objTable = objSelection.Tables(1)
			objTable.AllowAutoFit = False

			intTemplateRowNumber = CLng(objSelection.Information(wdStartOfRangeRowNumber))
			Set objTemplateRow = objTable.Rows(intTemplateRowNumber) 'Note - first row is a heading in this case
			objSelection.InsertRowsBelow 1
			intNewRowNumber = intTemplateRowNumber + 1
		
			' Loop through the records creating a table row for each day
			Do Until objRecordSet.EOF 

				objTable.Rows(intNewRowNumber).Range.FormattedText = objTemplateRow.Range.FormattedText
				objTable.Rows(intNewRowNumber).Select 

				' Populate the fields
				FindAndReplaceFields "trip_element", objFields, True, False

				objRecordSet.MoveNext
				intNewRowNumber = intNewRowNumber + 1
				
				CheckError "Unable to populate trip list " & strListName & " in recordset loop", False

			Loop
			
			objTable.Rows(intNewRowNumber).Delete 
			objTable.Rows(intTemplateRowNumber).Delete

		End If

		objRecordSet.Close
		
	End If
	
	CheckError "Unable to populate trip list " & strListName, False

End Sub


' ---Populate {list_of_flights} ---
Sub populate_list_of_flights

	PopulateTripList "list of flights", "sp_document_data_flights"

End Sub


'-- Populate {list_of_ground_elements_for_contact_sheet}
Sub populate_list_of_ground_elements_for_contact_sheet

	PopulateTripList "list of ground elements for contact sheet", "sp_document_data_ground_elements"
	
End Sub


'-- Populate {list_of_accommodation_for_contact_sheet}
Sub populate_list_of_accommodation_for_contact_sheet

	PopulateTripList "list of accommodation for contact sheet", "sp_document_data_accommodation"
	
End Sub


' --- Populate {list_of_daily_activities} ---
Sub populate_list_of_daily_activities

	Dim objDatesRecordSet
	Dim objDatesFields
	Dim objTable
	Dim intTemplateRowNumber
	Dim objTemplateRow
	Dim intNewRowNumber
	Dim strDayDate
	Dim objItemsRecordSet
	Dim objItemsFields
	Dim boolIgnoreDateField
	
	On Error Resume Next
	
	If(Not IsNumeric(strTripId)) Then

		ReportProgress(" - cannot build list of daily activities: no trip id")

	Else

		ReportProgress(" - building list of daily activities")
		
		' Get a recordset of days for the trip
		Set objDatesRecordSet = CreateObject("Adodb.Recordset")
		Set objDatesFields = objDatesRecordSet.Fields
		objDatesRecordSet.Open "EXEC sp_document_data_days " & strTripId, objSqlConnection
		
		If Not CheckTableDelete(objDatesRecordSet) Then

			' Initialise the table row copy mechanism
			Set objTable = objSelection.Tables(1)
			objTable.AllowAutoFit = False

			intTemplateRowNumber = CLng(objSelection.Information(wdStartOfRangeRowNumber))
			Set objTemplateRow = objTable.Rows(intTemplateRowNumber) 
			objSelection.InsertRowsBelow 1
			intNewRowNumber = intTemplateRowNumber + 1

			Set objItemsRecordSet = CreateObject("Adodb.Recordset")
			Set objItemsFields = objItemsRecordSet.Fields

			' Loop through the records creating a table row for each day
			Do Until objDatesRecordSet.EOF 

				' **TODO: there are possible quirks here
				' Notes: 	- it may be too slow, returning to server for every day - consider alternatives
				'			- if end_date is exactly midnight (as it usually is for accomodation), that day will not be included in the list
				' 			- start_date is rounded down to midnight so the comparison works
				'			- might want to consider union so flights, accomm and ground are treated differently
				'			- suppier_description only available if first day for item (might not fit all scenarios)
				' 			- ordered by type_id so flights will come first for a specific day
				'			- not sure supplier_location is right for heading item for accom as often it is missed out

				strDayDate = GetSQLFriendlyDate(objDatesFields.Item("day_date"))
				boolIgnoreDateField = false

				objItemsRecordSet.Open "EXEC sp_document_data_day_elements " & strTripId & ", '" & strDayDate & "'", objSqlConnection						

				' Add a row to the table for each element on this day:
				If NOT objItemsRecordSet.EOF Then

					Do Until objItemsRecordSet.EOF

						objTable.Rows(intNewRowNumber).Range.FormattedText = objTemplateRow.Range.FormattedText
						objTable.Rows(intNewRowNumber).Select 

						FindAndReplaceFields "trip_element", objItemsFields, True, boolIgnoreDateField 

						objItemsRecordSet.MoveNext
						boolIgnoreDateField = true 'only ignore the first time
						intNewRowNumber = intNewRowNumber + 1

						CheckError "Unable to populate list of daily activities in items loop", False

					Loop

				' When there are no elements on this day just add a blank row: (Added 30-Sep-2010 by GA)
				' Note: This assumes sp_document_data_day_elements can accept an extra parameter to generate a dummy row.
				Else

					' Generate a fake item to populate the row: (Notice the extra "1" parameter)
					' This approach means we can still call the FindAndReplaceFields function to replace all the tags in the row.
					objItemsRecordSet.Close
					objItemsRecordSet.Open "EXEC sp_document_data_day_elements " & strTripId & ", '" & strDayDate & "', 1", objSqlConnection						

					objTable.Rows(intNewRowNumber).Range.FormattedText = objTemplateRow.Range.FormattedText
					objTable.Rows(intNewRowNumber).Select 

					FindAndReplaceFields "trip_element", objItemsFields, True, boolIgnoreDateField 
					intNewRowNumber = intNewRowNumber + 1

				End If

				objItemsRecordSet.Close
				objDatesRecordSet.MoveNext

				CheckError "Unable to populate list of daily activities in days loop", False

			Loop

			objTable.Rows(intNewRowNumber).Delete 
			objTable.Rows(intTemplateRowNumber).Delete
		
		End If
		
		objDatesRecordSet.Close
		
		CheckError "Unable to populate list of daily activities", False
		
	End If
	
End Sub


' ---Parse Lists (all tags in the list of array)---
Sub ParseLists

	Dim strListName
	
	On Error Resume Next
	
	ReportProgress("Parsing lists...")

	objSelection.Find.ClearFormatting
	objSelection.Find.MatchWildCards = True	
	objSelection.HomeKey wdStory	

	Do Until objSelection.Find.Execute("\{list_of_*\}") = False 'keep finding lists until there are no more

		strListName = Mid(objSelection.Text, 2, Len(objSelection.Text) - 2)
		objSelection.Text = "" 'this means there will not be more than one attempt to parse each instance of the list

		If (objSelection.Information(wdWithinTable) = True) Then
		
			Execute "populate_" & strListName
			CheckError "Unable to execute method for list tag '" & strListName & "'", False

		Else
			' Report that list element is not inside a table cell
			Err.Raise 10004
			Err.Description = "Illegal tag"
			CheckError "List tag '" & strListName & "'is not in a table", True
		End If
		
		' Reset the Find parameters, changed by the pattern matching when replacing fields
		objSelection.Find.ClearFormatting
		objSelection.Find.MatchWildCards = True	
		objSelection.HomeKey wdStory	

		CheckError "Unable to parse lists", False

	Loop
		
	CheckError "Unable to parse lists", False
	
End Sub


' ---Parse Tags---
Sub ParseTags(strTagType, strId)

	Dim objRecordSet
	Dim objFields

	On Error Resume Next

	If (Not IsNumeric(strId)) Then

		ReportProgress("No id for " & strTagType & " tags")

	Else
	
		ReportProgress("Parsing " & strTagType & " tags for id " & strId & "...")

		Set objRecordSet = CreateObject("ADODB.Recordset")
		Set objFields = objRecordSet.Fields
		objRecordSet.Open "EXEC sp_document_data_" & strTagType & " " & strId, objSqlConnection						
		CheckError "Problem opening recordset " & strTagType, False

		If Not objRecordSet.EOF Then

			' Get any parameters from the recordsets. 

			' 2010-04-29: George has decided that script caller will provide ids if it has them so this will only
			' be used as a last resort. 
			' Note that if the field does not exist, the error is ignored
			If strTripId   = "" Then strTripId   = objFields.Item("trip_id")
			If strClientId = "" Then strClientId = objFields.Item("client_id")
			If strUserId   = "" Then strUserId   = objFields.Item("user_id")
			Err.Clear

			FindAndReplaceFields strTagType, objFields, False, False

		Else
			' Report user record not found
			Err.Raise 10005
			Err.Description = "Unable to parse fields"
			CheckError strTagType & " record with id " & strId & " not found.", False
		End If

		objRecordSet.Close
		
	End If
	
	CheckError "Unable to parse tags", False

End Sub

' --- Parse Misc Tags ---
' Fields for data not found in the database
Sub ParseMiscTags

	Dim strTagName
	Dim strFieldData
	
	On Error Resume Next
	
	ReportProgress("Parsing misc tags...")

	objSelection.Find.ClearFormatting
	objSelection.Find.MatchWildCards = true
	
	'Do each date_today field until it is not found any more
	objSelection.HomeKey wdStory
	Do Until objSelection.Find.Execute("\{today_*\}") = False 'keep finding today fields until there are no more

		If InStr(objSelection.Text, "_time") > 0 Then

			' {today_time}
			objSelection.Text = GetTime(Now)

		ElseIf InStr(objSelection.Text, "_date_full") > 0 Then

			' {today_date_full}
			objSelection.Text = GetFullDate(Now)

		ElseIf InStr(objSelection.Text, "_date_long") > 0 Then

			' {today_date_long}
			objSelection.Text = GetLongDate(Now)
			
		Else
		
			' {today_date} or other unexpected variation of today_*:
			objSelection.Text = GetStandardDate(Now)
		
		End If
		
		CheckError "Unable to parse misc tags " & objSelection.Text, False

		objSelection.HomeKey wdStory

	Loop
	
	CheckError "Unable to parse misc tags ", False
	
End Sub

'--- Report Success ---
Sub ReportSuccess

	ReportProgress "*Success*"

End Sub


' ---Main---

GetScriptArguments
ReadIniFile
OpenSQLConnection
GetJobParameters
UpdateJobStatus(1) 'update job status to "running"

InitialiseDocument

' Important: The ParseTags function expects to find corresponding stored procedures, eg: sp_document_data_brochure_request
ParseTags "invoice", strInvoiceId			' will get client id and user id if not provided
ParseTags "trip", strTripId					' will get user id if not provided
ParseTags "brochure_request", strBrochureId
ParseTags "user", strUserId 
ParseTags "client", strClientId  
ParseTags "voucher", strVoucherId

ParseMiscTags
ParseLists

FinaliseDocument

UpdateJobStatus(3) 'update job status to "complete"
ReportSuccess
CloseSqlConnection
