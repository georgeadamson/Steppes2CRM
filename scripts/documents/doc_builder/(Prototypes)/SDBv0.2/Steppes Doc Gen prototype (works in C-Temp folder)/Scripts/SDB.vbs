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
Const wdWithinTable = 12
Const wdStory = 6 
Const strIniFileName = "sdb.ini"
Const strUnknown = "*unknown*"
Const strFieldNotFound = "*field not found*"

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
	
	Wscript.Echo strDescription
	' TODO: place in the database?
	
End Sub

Function CheckError(strDescription, boolContinue)
	
	Dim strErrorReport
	Dim boolIsError

	boolIsError = False	
	If Err.Number <> 0 Then
	
		strErrorReport = strDescription & ": " & _
							Err.Description & " (" & _
							Err.Number & ")"
		Wscript.Echo strErrorReport
		
		' TODO: place in the database
		
		Err.Clear

		If Not boolContinue Then
			' update job status to failed
			UpdateJobStatus(2)
			Wscript.Quit
		End If
		
		boolIsError = True
		
	End If
	
	CheckError = boolIsError
	
End Function

' ---Get INI file settings---
Sub ReadIniFile()

	Dim strIniFileContents 
	
    On Error Resume Next
    
    ReportProgress("Getting INI file settings...")

	' Open the INI file
	strIniFileContents = objFSO.OpenTextFile(strIniFileName).ReadAll
	CheckError "Error at position #1. Unable to open INI file", False

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
		Err.Raise 9999
		Err.Description = "Cannot find INI file key " & strKeyName
		CheckError "Error at position #2. Unable to get INI key", False
	End If

	
	GetIniFileKey = strIniFileKeyValue

End Function


' ---Open SQL connection---
Sub OpenSQLConnection

	On Error Resume Next
	
	ReportProgress("Connecting to database...")
	
	Set objSqlConnection = CreateObject("Adodb.Connection")
	objSqlConnection.Open strConnectionString
	CheckError "Error at position #4. Unable to create SQL connection", False
	
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
	
	On Error Resume Next

	ReportProgress("Getting job parameters...")  
	
	' Run SQL to return the job parameters
	strJobSql = "SET ANSI_PADDING ON;" & _
				"SELECT dt.[file_name] AS template_name" & _
				"		, dj.[name] AS document_name" & _
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
	CheckError "Error at position #x. Cannot find open job recordset", False
	
	If objJobRecordSet.EOF Then 
		Err.Raise 9999
		Err.Description = "Cannot find job record"
		CheckError "Error at position #3. Cannot find job record", False
	Else
	    strTemplateFileName = strTemplatePath + "\" + objJobRecordSet.Fields.Item("template_name")
		ReportProgress(" - retrieved template file name: " & strTemplateFileName)    
	    strDocumentFileName = strDocumentPath + "\" + objJobRecordSet.Fields.Item("document_name")
	    'strDocumentFileName = StrReverse(Replace(StrReverse(strDocumentFileName), "cod.", "", 1, 1)) 'if it is there, remove the .doc from the end 
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

	'	- open template read only
	Set objTemplate = objWord.Documents.Open(strTemplateFileName, False, True)

	' Save document immediately - get path root from ini - 'ainder of path presented as parameter
	' **TODO: check this releases the template
	
	objTemplate.SaveAs(strDocumentFileName & ".running")
	
	Set objSelection = objWord.Selection

End Sub

' --- Date Functions ---

Function PadDate(dateString, totalDigits) 
	If totalDigits > len(dateString) then 
		PadDate = String(totalDigits - Len(dateString),"0") & dateString
	Else 
		PadDate = dateString
	End if 
End Function 

' --- Date format yyyy-mm-dd
Function GetSQLFriendlyDate(dateString)

	GetSQLFriendlyDate = PadDate(Right(Year(dateString),4),2) & "-" & _ 
        PadDate(Month(dateString),2) & "-" & _ 
        PadDate(Day(dateString),2)
        
End Function


' --- Date format dd/mm/yyyy
Function GetStandardDate(dateString)

	GetStandardDate = PadDate(Day(dateString),2) & "/" & _ 
        PadDate(Month(dateString),2) & "/" & _ 
        PadDate(Right(Year(dateString),4),2) 
        
End Function

' --- Date format dddd dd mmm 
Function GetLongDate(dateString)

	GetLongDate = WeekDayName(WeekDay(dateString)) & " " & _ 
        Day(dateString) & " " & _ 
        MonthName(Month(dateString)) 
        
End Function

' --- Date format dd mmm yyyy
Function GetFullDate(dateString)

	GetFullDate = Day(dateString) & " " & _ 
        MonthName(Month(dateString)) & " " & _
        Right(Year(dateString),4) 
        
End Function

Function GetTime(dateString)

	GetTime = PadDate(Hour(dateString), 2) & ":" & _ 
        PadDate(Minute(dateString), 2) 
        
End Function


' --- Insert data functions ---
Sub PopulateListField(strTagName, strFieldData)

	objSelection.SelectRow()
	If objSelection.Find.Execute("{" + strTagName + "}") = True Then
		objSelection.Text = strFieldData
	End If

End Sub

' ---Populate list functions---

' ---Populate list_of_flights---
Redim Preserve arrListOfTags(UBound(arrListOfTags) + 1)
arrListOfTags(UBound(arrListOfTags)) = "list_of_flights"
Sub populate_list_of_flights()

	Dim strFlightsSql
	Dim objFlightsRecordSet
	Dim objFlightsFields
	Dim objTable
	Dim objTemplateRow

	ReportProgress(" - building list_of_flights")
	
	' Clear the list tag
	objSelection.Text = ""
	Set objTable = objSelection.Tables(1)
	Set objTemplateRow = objTable.Rows(2) 'Note - first row is a heading
	
	'**TODO: check the trip id is numeric
	
	' Get the recordset of daily activities for the trip
	strFlightsSql = 	"SELECT " & _
						"	te.start_date " & _
						"	, te.end_date " & _
						"	, te.flight_code " & _
						"	, ad.name AS depart_airport_name " & _
						"	, aa.name AS arrive_airport_name  " & _
						"	, CASE WHEN arrive_next_day = 1 THEN '*' ELSE '' END AS arrive_next_day " & _
						"FROM trip_elements te " & _
						"	LEFT JOIN suppliers s ON te.supplier_id = s.id " & _
						"	LEFT JOIN airports ad ON te.depart_airport_id = ad.id " & _
						"	LEFT JOIN airports aa ON te.arrive_airport_id = aa.id " & _
						"WHERE te.trip_id = " & strTripId & _
						"	AND te.kind_id = 1 " & _
						"ORDER BY te.start_date "
	
	' Loop through the records creating a table row for each day
	Set objFlightsRecordSet = CreateObject("Adodb.Recordset")
	objFlightsRecordSet.Open strFlightsSql, objSqlConnection
	
	objTable.Rows.Add
	Do Until objFlightsRecordSet.EOF 
	
		Set objFlightsFields = objFlightsRecordSet.Fields

		objTable.Rows(objTable.Rows.Count).Range.FormattedText = objTemplateRow.Range.FormattedText
		objTable.Rows(objTable.Rows.Count - 1).Select 

		'**TODO: handling of empty record fields

		' Populate the fields
		' **TODO: Slightly more intelligent parser may pass recordset and field name to function
		' 	function can parse for date and time depending on instr for field name
		
		PopulateListField "trip_element.start_date", GetStandardDate(objFlightsRecordSet.Fields.Item("start_date"))
		PopulateListField "trip_element.depart_airport_name", objFlightsFields.Item("depart_airport_name")
		PopulateListField "trip_element.arrive_airport_name", objFlightsFields.Item("arrive_airport_name")
		PopulateListField "trip_element.flight_code", objFlightsFields.Item("flight_code")
'*TODO		PopulateListField "trip_element.check_in_time", objFlightsFields.Item("check_in_time")
		PopulateListField "trip_element.start_time", GetTime(objFlightsFields.Item("start_date"))
		PopulateListField "trip_element.end_time", GetTime(objFlightsFields.Item("end_date"))
		PopulateListField "trip_element.arrive_next_day", objFlightsFields.Item("arrive_next_day")

		objFlightsRecordSet.MoveNext

	Loop
	
	objTable.Rows(objTable.Rows.Count).Delete '**TODO: may be a better solution for the extra row being added
	objTable.Rows(2).Delete
	
	objFlightsRecordSet.Close
	
End Sub

' ---Populate list_of_daily_activities---
Redim Preserve arrListOfTags(UBound(arrListOfTags) + 1)
arrListOfTags(UBound(arrListOfTags)) = "list_of_daily_activities"
Sub populate_list_of_daily_activities()

	Dim strDatesSql
	Dim objDatesRecordSet
	Dim objDatesFields
	Dim objTable
	Dim objTemplateRow
	Dim strDayDate
	Dim strItemsSql
	Dim objItemsRecordSet
	Dim objItemsFields
	Dim dateElementDate
	Dim dateElementStartDate
	Dim dateElementEndDate
	Dim dayItemsCount

	ReportProgress(" - building list_of_daily_activities")
	
	' Clear the list tag
	objSelection.Text = ""
	Set objTable = objSelection.Tables(1)
	Set objTemplateRow = objTable.Rows(1)
	objTable.Rows.Add 'do this once (rather than for each row as makes sense)
	
	'**TODO: check the trip id is numeric
	
	' Get a recordset of days for the trip
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

	Set objItemsRecordSet = CreateObject("Adodb.Recordset")
	Do Until objDatesRecordSet.EOF 
	
		Set objDatesFields = objDatesRecordSet.Fields

		' **TODO: there are possible quirks here
		' Notes: 	- it may be too slow, returning to server for every day - consider alternatives
		'			- if end_date is exactly midnight (as it usually is for accomodation), that day ill not be included in the list
		' 			- start_date is rounded down to midnight so the comparison works
		'			- might want to consider union so flights, accomm and ground are treated differently
		'			- suppier_description only available if first day for item (might not fit all scenarios)
		' 			- ordered by type_id so flights will come first for a specific day
		'			- not sure supplier_location is is right for heading item for accom
		strDayDate = GetSQLFriendlyDate(objDatesFields.Item("day_date"))
		
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
						"	LEFT JOIN suppliers s ON te.supplier_id = s.id " & _
						"	LEFT JOIN airports ad ON te.depart_airport_id = ad.id " & _
						"	LEFT JOIN airports aa ON te.arrive_airport_id = aa.id "  & _
						"WHERE te.trip_id = " & strTripID & _
						"	AND ((DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) <= '" & strDayDate & "' " & _
						"	AND te.end_date > '" & strDayDate & "') " & _
						"	OR (te.end_date < te.start_date AND DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) = '" & strDayDate & "')) " & _
						"	AND (te.kind_id = 1 OR te.kind_id = 4 OR te.kind_id = 5) " & _
						"ORDER BY DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0), te.kind_id"
						
		'wscript.echo strItemsSql				
						
		objItemsRecordSet.Open strItemsSql, objSqlConnection						
		
		dayItemsCount = 0
		
		Do Until objItemsRecordSet.EOF
		
			Set objItemsFields = objItemsRecordSet.Fields
		
			objTable.Rows(objTable.Rows.Count).Range.FormattedText = objTemplateRow.Range.FormattedText
			objTable.Rows(objTable.Rows.Count - 1).Select 
			
			'**TODO: handling of empty record fields
			
			' Populate the fields
			' Only display the date fields if this is the first time the day is displayed
			If(dayItemsCount < 1) Then
				PopulateListField "day_date", GetStandardDate(strDayDate)
				PopulateListField "day_date_long", GetLongDate(strDayDate)
			Else
				PopulateListField "day_date", ""
				PopulateListField "day_date_long", ""
			End If
			PopulateListField "trip_element.supplier_name", objItemsFields.Item("supplier_name")
			PopulateListField "trip_element.supplier_location", objItemsFields.Item("supplier_location")
			
			' Description or images not displayed if not start date
			PopulateListField "trip_element.supplier_description", objItemsFields.Item("supplier_description")
			'**TODO: supplier_image
			
			objItemsRecordSet.MoveNext
			
			dayItemsCount = dayItemsCount + 1
			
		Loop
		objItemsRecordSet.Close
		objDatesRecordSet.MoveNext
		
	Loop

	objTable.Rows(objTable.Rows.Count).Select 
	objTable.Rows(1).Delete
	
	objDatesRecordSet.Close
	
End Sub



' ---Parse Lists (all tags in the list of array)---
Sub ParseLists()
	Dim list
	
	ReportProgress("Parsing lists...")

	objSelection.Find.ClearFormatting()
	objSelection.Find.MatchWildCards = false	
	For Each list In arrListOfTags

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


' ---Parse Tags---
Sub ParseTags(strFieldType, strSql)

	Dim objRecordSet
	Dim objFields
	Dim strFieldName
	Dim strFieldData
	
	On Error Resume Next
	
	ReportProgress("Parsing " & strFieldType & " fields...")

	Set objRecordSet = CreateObject("Adodb.Recordset")
	objRecordSet.Open strSql, objSqlConnection						
	CheckError "Problem opening recordset " & strFieldType & ". Sql: " & strSql, False
		
	If Not objRecordSet.EOF Then
	
		Set objFields = objRecordSet.Fields
	
		'Do each field until it is not found any more
		objSelection.HomeKey wdStory
		objSelection.Find.ClearFormatting()
		objSelection.Find.MatchWildCards = true	
		Do Until objSelection.Find.Execute("\{" & strFieldType & ".*\}") = False 'keep finding user fields until there are no more
	
			'replace the selection with the correct field from the table
			strFieldName = Replace(Replace(objSelection.Text, "{" & strFieldType & ".", ""), "}", "")

			If InStr(strFieldName, "date_full") > 0 Then
				strFieldData = objFields.Item(Replace(strFieldName, "date_full", "date")) 'date_full is a formatting not an actual field
			ElseIf InStr(strFieldName, "date_long") > 0 Then
				strFieldData = objFields.Item(Replace(strFieldName, "date_long", "date")) 'date_long is a formatting not an actual field
			Else
				strFieldData = objFields.Item(strFieldName)
			End If
			
			If CheckError("Problem with field " & strFieldType & "." & strFieldName, True) Then
				strFieldData = strFieldNotFound ' **TODO: might want to not replace these tags
			End If
			
			'special cases
			
			If Instr(strFieldName, "_portrait") > 0 Then
				
				' **TODO: do portrait stuff
				
			Else
			
				If strFieldName = "countries" _
						Or strFieldName = "client_names" Then 'replace last comma with AND (cant do easily in SQL
					strFieldData = StrReverse(Replace(StrReverse(strFieldData), ",", "& ", 1, 1))
				ElseIf InStr(strFieldName, "date_full") > 0 Then
					strFieldData = GetFullDate(strFieldData)
				ElseIf InStr(strFieldName, "date_long") > 0 Then
					strFieldData = GetLongDate(strFieldData)
				ElseIf InStr(strFieldName, "date") > 0 Then
					strFieldData = GetStandardDate(strFieldData)
				ElseIf InStr(strFieldName, "net_") > 0 _
						Or InStr(strFieldName, "_net") > 0 _ 
						Or InStr(strFieldName, "cost_") > 0 _
						Or InStr(strFieldName, "_cost") > 0 _
						Or InStr(strFieldName, "price_") > 0 _
						Or InStr(strFieldName, "_price") > 0 _
						Or InStr(strFieldName, "gross_") > 0 _
						Or InStr(strFieldName, "_gross") > 0 Then
					strFieldData = FormatNumber(strFieldData, 2)
				End If
				
				If IsNull(strFieldData) Then
					strFieldData = ""
				End If

				objSelection.Text = strFieldData
				
			End If
			
			' set the selection back to the start of the doc
			objSelection.HomeKey wdStory
		Loop
	
	Else
		' Report user record not found
		Err.Raise 9999
		Err.Description = strFieldType & " record not found. Sql: " & strSql
		CheckError "Error at position #**. Unable to parse fields", True
	End If
	
	objRecordSet.Close

End Sub



' ---Main---

GetScriptArguments()
ReadIniFile()
OpenSQLConnection()
GetJobParameters()
UpdateJobStatus(1)

InitialiseDocument()

ParseTags "user", "SELECT u.* " & vbCrlf & _
					"		, c.name AS company_name " & vbCrlf & _
					"FROM users u " & vbCrlf & _
					"INNER JOIN companies c ON u.company_id = c.id " & vbCrlf & _
					"WHERE u.id = " & strUserId

ParseTags "trip", "SELECT t.*  " & vbCrlf & _
					"		, tv1.name AS title  " & vbCrlf & _
					"		, ISNULL((SELECT TOP 1 a.name FROM trip_elements te " & vbCrlf & _
					"			LEFT JOIN airports a ON te.depart_airport_id = a.id " & vbCrlf & _
					"		WHERE te.kind_id = 1 " & vbCrlf & _
					"			AND te.trip_id = t.id " & vbCrlf & _
					"		ORDER BY te.start_date), '') AS first_flight_depart_airport_name" & vbCrlf & _
					"		, ISNULL((SELECT STUFF(( SELECT DISTINCT ', ' + cl.fullname " & vbCrlf & _
					"			FROM trip_clients tc " & vbCrlf & _
					"			LEFT JOIN clients cl " & vbCrlf & _
					"			ON tc.client_id = cl.id " & vbCrlf & _
					"			WHERE tc.trip_id = t.id " & vbCrlf & _
					"			FOR XML PATH('')), 1, 1, '')), '') " & vbCrlf & _
		  			"			AS client_names " & vbCrlf & _
					"		, ISNULL((SELECT STUFF(( SELECT DISTINCT ', ' + [name] " & vbCrlf & _
					"			FROM trip_countries tc  " & vbCrlf & _
					"			LEFT JOIN countries c  " & vbCrlf & _
					"			ON c.id = tc.country_id " & vbCrlf & _
					"			WHERE tc.trip_id = t.id " & vbCrlf & _
					"			FOR XML PATH('')), 1, 1, '')), '')  " & vbCrlf & _
					"		  AS countries " & vbCrlf & _
					"		, REPLACE(ISNULL((SELECT STUFF(( SELECT DISTINCT CHAR(10) + CHAR(10) + inclusions " & vbCrlf & _
					"			FROM trip_countries tc  " & vbCrlf & _
					"			LEFT JOIN countries c  " & vbCrlf & _
					"			ON c.id = tc.country_id " & vbCrlf & _
					"			WHERE tc.trip_id = t.id " & vbCrlf & _
					"			FOR XML PATH('')), 1, 1, '')), ''), '&#x0D;', '')  " & vbCrlf & _
					"		  AS countries_inclusions " & vbCrlf & _
					"		, REPLACE( ISNULL((SELECT STUFF(( SELECT DISTINCT CHAR(10) + CHAR(10) + exclusions " & vbCrlf & _
					"			FROM trip_countries tc  " & vbCrlf & _
					"			LEFT JOIN countries c  " & vbCrlf & _
					"			ON c.id = tc.country_id " & vbCrlf & _
					"			WHERE tc.trip_id = t.id " & vbCrlf & _
					"			FOR XML PATH('')), 1, 1, '')), ''), '&#x0D;', '')  " & vbCrlf & _
					"		  AS countries_exclusions " & vbCrlf & _
					"		, REPLACE( ISNULL((SELECT STUFF(( SELECT DISTINCT CHAR(10) + CHAR(10) + notes " & vbCrlf & _
					"			FROM trip_countries tc  " & vbCrlf & _
					"			LEFT JOIN countries c  " & vbCrlf & _
					"			ON c.id = tc.country_id " & vbCrlf & _
					"			WHERE tc.trip_id = t.id " & vbCrlf & _
					"			FOR XML PATH('')), 1, 1, '')), ''), '&#x0D;', '')  " & vbCrlf & _
					"		  AS countries_notes " & vbCrlf & _
					"		FROM trips t " & vbCrlf & _
					"	LEFT JOIN trips tv1 ON t.version_of_trip_id = tv1.id  " & vbCrlf & _
					"	WHERE t.id = " & strTripId
	

ParseTags "client",  "SELECT TOP 1 " & vbCrlf & _  
						"	* " & vbCrlf & _
						"	, CASE WHEN ISNULL(address1, '') = '' THEN '' ELSE address1 + CHAR(10) END " & vbCrlf & _
						"	+ CASE WHEN ISNULL(address2, '') = '' THEN '' ELSE address2 + CHAR(10) END " & vbCrlf & _
						"	+ CASE WHEN ISNULL(address3, '') = '' THEN '' ELSE address3 + CHAR(10) END " & vbCrlf & _
						"	+ CASE WHEN ISNULL(address4, '') = '' THEN '' ELSE address4 + CHAR(10) END " & vbCrlf & _
						"	+ CASE WHEN ISNULL(address5, '') = '' THEN '' ELSE address5 + CHAR(10) END " & vbCrlf & _
						"	+ CASE WHEN ISNULL(address6, '') = '' THEN '' ELSE address6 + CHAR(10) END " & vbCrlf & _
						"	+ CASE WHEN ISNULL(postcode, '') = '' THEN '' ELSE postcode + CHAR(10) END " & vbCrlf & _
						"	+ CASE WHEN ISNULL(b.country_id, 0) = 0 THEN '' ELSE co.[name] + CHAR(10) END " & vbCrlf & _
						"	AS [address] " & vbCrlf & _
						"FROM clients c " & vbCrlf & _
						"INNER JOIN ( " & vbCrlf & _
						"	SELECT " & vbCrlf & _
						"		ca.client_id " & vbCrlf & _
						"		, a.*  " & vbCrlf & _
						"	FROM client_addresses ca " & vbCrlf & _
						"		INNER JOIN addresses a ON ca.address_id = a.id " & vbCrlf & _
						"	WHERE is_active = 1  " & vbCrlf & _
						") b ON c.id = b.client_id " & vbCrlf & _
						"	LEFT JOIN countries co ON co.id = b.country_id " & vbCrlf & _
						"	WHERE c.id= " & strClientId
						
						
'ParseInvoiceFields()
'ParseVoucherFields()
'ParseOtherFields()

ParseLists()

'SaveDocument()


UpdateJobStatus(3)

CloseSqlConnection()
