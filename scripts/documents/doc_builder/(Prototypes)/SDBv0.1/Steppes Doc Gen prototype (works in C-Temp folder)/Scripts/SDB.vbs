' -------------------------------
' SDB.vbs
' Steppes Travel Document Builder
' by Nick Casey 2010-04-23
' -------------------------------

' Required Files and Settings:
' 	SDB.INI in same folder as Script
'		Steppes database as set up in INI connection string
'		Template Path as set up in INI connection string
'		Document Path as set up in INI connection string
'		Image Path as set up in INI connection string


Option Explicit 

' ---Global Constants---
Const wdCharacter = 1
Const wdWithinTable = 12
Const strIniFileName = "sdb.ini"
Const strUnknown = "*unknown*"

' ---Global Variables---
Dim objFSO 
Set objFSO = CreateObject("Scripting.FileSystemObject")

Dim objSqlConnection

Dim strJobId

Dim strConnectionString
Dim strTemplatePath
Dim strDocumentPath
Dim strImagePath
Dim strSignaturePath
Dim strPortraitPath

Dim strTemplateFileName
Dim strDocumentFileName
Dim strClientId
Dim strTripId
Dim strUserId
Dim strInvoiceId
Dim strVoucherId

Dim objWord
Dim objTemplate
Dim objDocument
Dim objRange
Dim objSelection

Dim arrListOfTags()
Redim arrListOfTags(0)


' ---Error Handling---

Sub ReportProgress(strDescription)
	
	'Wscript.Echo strDescription
	' TODO: place in the database?
	
End Sub

Sub CheckError(strDescription)
	
	dim strErrorReport
	If Err.Number <> 0 Then
	
		strErrorReport = strDescription & ": " & _
							Err.Description & " (" & _
							Err.Number & ")"
		Wscript.Echo strErrorReport
		
		' TODO: place in the database
		
		' update job status to failed
		UpdateJobStatus(2)
		
		Wscript.Quit
	End If
	
End Sub

' ---Get INI file settings---
Sub ReadIniFile()

	Dim strIniFileContents 
	
    On Error Resume Next
    
    ReportProgress("Getting INI file settings...")

	' Open the INI file
	strIniFileContents = objFSO.OpenTextFile(strIniFileName).ReadAll
	CheckError("Error at position #1. Unable to open INI file")

	' Get keys
	strConnectionString = GetIniFileKey(strIniFileContents, "ConnectionString")
	ReportProgress(" - retrieved connection string from INI file: " & strConnectionString)
	strTemplatePath = GetIniFileKey(strIniFileContents, "TemplatePath")
	ReportProgress(" - retrieved template path from INI file: " & strTemplatePath)
	strDocumentPath = GetIniFileKey(strIniFileContents, "DocumentPath")
	ReportProgress(" - retrieved document path from INI file: " & strDocumentPath)
	strImagePath = GetIniFileKey(strIniFileContents, "ImagePath")
	ReportProgress(" - retrieved image path: " & strImagePath)
	strSignaturePath = GetIniFileKey(strIniFileContents, "SignaturePath")
	ReportProgress(" - retrieved signature path: " & strSignaturePath)
	strPortraitPath = GetIniFileKey(strIniFileContents, "PortraitPath")
	ReportProgress(" - retrieved portrait path: " & strPortraitPath)
	
	ReportProgress("")
	  
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
		Err.Raise 8
		Err.Description = "Cannot find INI file key " & strKeyName
		CheckError("Error at position #2. Unable to get INI key")
	End If

	
	GetIniFileKey = strIniFileKeyValue

End Function


' ---Open SQL connection---
Sub OpenSQLConnection

	On Error Resume Next
	
	ReportProgress("Connecting to database...")
	
	Set objSqlConnection = CreateObject("Adodb.Connection")
	objSqlConnection.Open strConnectionString
	CheckError("Error at position #4. Unable to create SQL connection")
	
End Sub

' ---Close SQL connection---
Sub CloseSqlConnection

	objSqlConnection.Close

End Sub


Sub GetScriptArguments

	Dim arguments, totalArguments
	
	' Get the jobId as the only argument to the script

	Set arguments = WScript.Arguments
	totalArguments = arguments.Count
	
	If totalArguments  < 1 then
	    WScript.Echo "Usage: [CScript | WScript] SDB.vbs <jobid>"
	    WScript.Quit
	Else
		strJobId = arguments.Item(0)
	End If
	
End Sub

' Update the job status with supplied status
' 0 - pending, 1 - running, 2 - failed, 3 - success
Sub UpdateJobStatus(status)

	Dim strUpdateStatusSql
	
	ReportProgress("Updating job status to " & status & "...")  

	strUpdateStatusSql = "UPDATE document_jobs SET document_status_id=" & status & _
							"WHERE id=" & strJobId + ";"
	objSqlConnection.Execute strUpdateStatusSql

End Sub


' ---Get Job parameters---
Sub GetJobParameters()

	Dim strJobSql
	Dim objJobRecordSet

	ReportProgress("Getting job parameters...")  
	
	' Run SQL to return the job parameters
	strJobSql = "SET ANSI_PADDING ON;" & _
				"SELECT dt.[file_name] AS template_name" & _
				"		, dj.[name] + '.doc' AS document_name" & _
				"		, [parameters].query('data(//client_id)') AS client_id		" & _
				"		, [parameters].query('data(//trip_id)') AS trip_id		" & _
				"		, [parameters].query('data(//user_id)') AS user_id		" & _
				"		, [parameters].query('data(//invoice_id)') AS invoice_id	" & _	
				"		, [parameters].query('data(//voucher_id)') AS voucher_id	" & _	
				"FROM document_jobs dj " & _	
				"		INNER JOIN document_templates dt " & _	
				"		ON dj.document_template_id = dt.id " & _	
				"WHERE dj.id=" & strJobId + ";"
				
	
	Set objJobRecordSet = CreateObject("Adodb.Recordset")
	objJobRecordSet.Open strJobSql, objSqlConnection
	
	If objJobRecordSet.EOF Then 
		Err.Raise 8
		Err.Description = "Cannot find job record"
		CheckError("Error at position #3. Cannot find job record")	    
	Else
	    strTemplateFileName = strTemplatePath + "\" + objJobRecordSet.Fields.Item("template_name")
		ReportProgress(" - retrieved template file name: " & strTemplateFileName)    
	    strDocumentFileName = strDocumentPath + "\" + objJobRecordSet.Fields.Item("document_name")
		ReportProgress(" - retrieved document file name: " & strDocumentFileName)    
		strClientId = objJobRecordSet.Fields.Item("client_id")
		ReportProgress(" - retrieved client id: " & strClientId)    
		strTripId = objJobRecordSet.Fields.Item("trip_id")
		ReportProgress(" - retrieved trip id: " & strTripId)    
		strUserId = objJobRecordSet.Fields.Item("user_id")
		ReportProgress(" - retrieved user id: " & strUserId)    
		strInvoiceId = objJobRecordSet.Fields.Item("invoice_id")
		ReportProgress(" - retrieved invoice id: " & strInvoiceId)    
		strVoucherId = objJobRecordSet.Fields.Item("voucher_id")
		ReportProgress(" - retrieved voucher id: " & strVoucherId)    
	    
	End If
	
	objJobRecordSet.Close()
	
	ReportProgress("")

End Sub

' ---End of Populate list functions---

' ---Create document by saving a copy of the template---
Sub InitialiseDocument()

	Set objWord = CreateObject("Word.Application")
	objWord.Visible = True
	objWord.ScreenUpdating = False


	'	- open template read only
	Set objTemplate = objWord.Documents.Open(strTemplateFileName, False, True)

	' Save document immediately - get path root from ini - 'ainder of path presented as parameter
	' **TODO: check this releases the template
	objTemplate.SaveAs(strDocumentFileName + "_Running.doc")

End Sub

' --- Date Functions ---

Function PadDate(dateString, totalDigits) 
	If totalDigits > len(dateString) then 
		PadDate = String(totalDigits - Len(dateString),"0") & dateString
	Else 
		PadDate = dateString
	End if 
End Function 


Function GetSQLFriendlyDate(dateString)

	GetSQLFriendlyDate = PadDate(Right(Year(dateString),4),2) & "-" & _ 
        PadDate(Month(dateString),2) & "-" & _ 
        PadDate(Day(dateString),2)
        
End Function


Function GetStandardDate(dateString)

	GetStandardDate = PadDate(Day(dateString),2) & "-" & _ 
        PadDate(Month(dateString),2) & "-" & _ 
        PadDate(Right(Year(dateString),4),2) 
        
End Function


Function GetShortDate(dateString)

	GetShortDate = WeekDayName(WeekDay(dateString)) & " " & _ 
        Day(dateString) & " " & _ 
        MonthName(Month(dateString)) 
        
End Function

Sub PopulateListField(tag, data, objRow)

	objSelection.SelectRow()
	If objSelection.Find.Execute("{" + tag + "}") = True Then
		objSelection.Text = data
	End If

End Sub


' ---Populate list functions---

' ---Populate list_of_daily_activities---
Redim Preserve arrListOfTags(UBound(arrListOfTags) + 1)
arrListOfTags(UBound(arrListOfTags)) = "list_of_daily_activities"
Sub populate_list_of_daily_activities()

	Dim strDatesSql
	Dim objDatesRecordSet
	Dim objRow
	Dim objRows
	Dim objTable
	Dim objTemplateRow
	Dim strDayDate
	Dim strItemsSql
	Dim objItemsRecordSet
	Dim dateElementDate
	Dim dateElementStartDate
	Dim dateElementEndDate
	Dim rsFields

	ReportProgress(" - building list_of_daily_activities")
	
	' Clear the list tag
	objSelection.Text = ""
	Set objTable = objSelection.Tables(1)
	Set objRows  = objTable.Rows
	Set objTemplateRow = objTable.Rows(1)
	
	'**TODO: check the trip id is numeric
	
	' Get the recordset of daily activities for the trip
	strDatesSql = 	"DECLARE @StartDate datetime; " & _
					"DECLARE @ENDDate datetime; " & _
					"SELECT " & _
					"	@StartDate = MIN(start_date) " & _
					"	, @EndDate = MAX(start_date) " & _
					"FROM trip_elements " & _
					"where trip_id = " + strTripId + " AND type_id = 4 " & _
					"GROUP BY trip_id;" & _
					"WITH Dates AS (" & _
        			"	SELECT" & _
         			"   [Date] = @StartDate " & _
        			"UNION ALL SELECT " & _
        			" 	[Date] = DATEADD(DAY, 1, [Date]) " & _
        			"FROM " & _
        			"	 Dates " & _
        			"WHERE Date <= @EndDate " & _
					")SELECT " & _
					"	 [Date] AS day_date " & _
					"FROM " & _
 					"	 Dates " & _
					"OPTION (MAXRECURSION 400)"
	
	' Loop through the records creating a table row for each day
	Set objDatesRecordSet = CreateObject("Adodb.Recordset")
	objDatesRecordSet.Open strDatesSql, objSqlConnection
	
	Do Until objDatesRecordSet.EOF 

		' **TODO: there are possible quirks here
		' Notes: 	- it may be too slow, returning to server for every day - consider alternatives
		'			- if end_date is exactly midnight (as it usually is for accomodation), that day ill not be included in the list
		' 			- start_date is rounded down to midnight so the comparison works
		'			- might want to consider union so flights, accomm and ground are treated differently
		'			- suppier_description only available if first day for item (might not fit all scenarios)
		' 			- ordered by type_id so flights will come first for a specific day
		'			- not sure supplier_location is is right for heading item for accom
		strDayDate = GetSQLFriendlyDate(objDatesRecordSet.Fields.Item("day_date"))
		
		strItemsSql = 	"SELECT te.kind_id" & _
						"		, te.start_date" & _
						"		, te.end_date" & _
						"		, ISNULL(s.name, '') AS supplier_name" & _
						"		, CASE WHEN te.kind_id = 1 " & _
						"				THEN 'Fly ' + ad.name + '/' + aa.name + CASE WHEN arrive_next_day = 1 " & _
						"															THEN ' (overnight)' " & _
						"															ELSE '' " & _
						"															END " & _
						"				ELSE ISNULL(s.location, '') " & _
						"				END AS supplier_location" & _
						"		, CASE WHEN DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) = '" & strDayDate & "'" & _
						"				THEN ISNULL(s.description,'') " & _
						"				ELSE '' " & _
						"				END AS supplier_description "  & _
						"FROM trip_elements te" & _
						"	INNER JOIN suppliers s ON te.supplier_id = s.id " & _
						"	LEFT JOIN airports ad ON te.depart_airport_id = ad.id " & _
						"	LEFT JOIN airports aa ON te.arrive_airport_id = aa.id "  & _
						"WHERE te.trip_id = " & strTripID & _
						"	AND ((DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) <= '" & strDayDate & "' " & _
						"	AND te.end_date > '" & strDayDate & "') " & _
						"	OR (te.end_date < te.start_date AND DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) = '" & strDayDate & "')) " & _
						"	AND (te.kind_id = 1 OR te.kind_id = 4 OR te.kind_id = 5) " & _
						"ORDER BY te.start_date, te.kind_id"
						
		'wscript.echo strItemsSql				
						
		Set objItemsRecordSet = CreateObject("Adodb.Recordset")
		objItemsRecordSet.Open strItemsSql, objSqlConnection		
		
		Set rsFields = objItemsRecordSet.Fields				
		
		objRows.Add
		
		Do Until objItemsRecordSet.EOF
		
			'objTable.Rows.Add
			objRows(objRows.Count).Range.FormattedText = objTemplateRow.Range.FormattedText
			'objRows(objRows.Count).Delete '**TODO: may be a better solution for the extra row being added
			objRows(objRows.Count -1 ).Select 
			
			'**TODO: handling of empty record fields
			Set objRow = objWord.Selection
			
			' Populate the fields
			PopulateListField "day_date", GetStandardDate(strDayDate), objRow.Range
			PopulateListField "day_date_long", GetShortDate(strDayDate), objRow.Range
			PopulateListField "trip_element.supplier_name", rsFields("supplier_name"), objRow.Range
			PopulateListField "trip_element.supplier_location", rsFields("supplier_location"), objRow.Range
			
			' Description or images not displayed if not start date
			PopulateListField "trip_element.supplier_description", rsFields("supplier_description"), objRow.Range
			'**TODO: supplier_image
			
			objItemsRecordSet.MoveNext
			
		Loop
		objItemsRecordSet.Close
		objDatesRecordSet.MoveNext
		
	Loop
	
	objDatesRecordSet.Close
	
	objTable.Rows(1).Delete
	
	
End Sub

' ---Parse Lists (all tags in the list of array)---
Sub ParseLists()
	Dim list
	
	ReportProgress("Parsing lists...")
	
	Set objSelection = objWord.Selection
	For Each list In arrListOfTags

		objSelection.Find.ClearFormatting()
		Do Until objSelection.Find.Execute("{" & list & "}") = False 'keep finding lists until there are no more
		
			If (objSelection.Information(wdWithinTable) = True) Then
				Execute "populate_" & Mid(objSelection.Text, 2, Len(objSelection.Text) - 2)
				objWord.ActiveDocument.Range.Select()			
			Else
					
				'**TODO report that list element is not inside a table cell
				
			End If
		Loop
	Next

End Sub



' ---Main---

GetScriptArguments()
ReadIniFile()
OpenSQLConnection()
GetJobParameters()
UpdateJobStatus(1)

InitialiseDocument()
ParseLists()
'ParseClientFields()
'ParseTripFields()
'ParseUserFields()
'ParseInvoiceFields()
'ParseVoucherFields()

UpdateJobStatus(3)

CloseSqlConnection()



objWord.ScreenUpdating = True
objWord.Visible = True