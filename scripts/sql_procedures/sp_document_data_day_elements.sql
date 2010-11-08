USE [steppes2dev]
GO

/****** Object:  StoredProcedure [dbo].[sp_document_data_day_elements]    Script Date: 09/30/2010 14:19:55 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_document_data_day_elements]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_document_data_day_elements]
GO

/****** Object:  StoredProcedure [dbo].[sp_document_data_day_elements]    Script Date: 09/30/2010 14:19:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-28
-- Description:	Returns list of elements for a particular day in the specified trip
-- Changes:		2010-09-30 - Added option to generate a dummy element row (allows doc builder script to add empty days).
-- =============================================
CREATE PROCEDURE [dbo].[sp_document_data_day_elements]
	@trip_id	int,
	@date		smalldatetime,
	@dummy_day	bit = 0			-- Use @dummy_day=1 to generate a blank day element.
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @FLIGHT  int; SET @FLIGHT  = 1
	DECLARE @HANDLER int; SET @HANDLER = 2
	DECLARE @ACCOMM  int; SET @ACCOMM  = 4
	DECLARE @GROUND  int; SET @GROUND  = 5
	DECLARE @MISC    int; SET @MISC    = 8


	IF ISNULL(@dummy_day,0) = 0 BEGIN

		-- Default to fetch all elements for the day:

		SELECT te.kind_id
				, @date AS [display_date]
				, te.start_date
				, te.end_date
				, ISNULL(s.name, '') AS [supplier_name]
				
				--, CASE WHEN te.kind_id = 1 
				--		THEN 'Fly ' + ad.name + '/' + aa.name + CASE WHEN arrive_next_day = 1 
				--													THEN ' (overnight)' 
				--													ELSE '' 
				--													END 
				--		ELSE ISNULL(s.location, '') 
				--		END AS [supplier_location]
						
				, CASE WHEN DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) = @date
						THEN ISNULL(s.description,'') 
						ELSE '' 
						END AS [supplier_description] 
				, CASE WHEN DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) = @date
						THEN ISNULL(s.image_file,'') 
						ELSE '' 
						END AS [supplier_image_file]
						
				, CASE
					WHEN te.kind_id = @ACCOMM   THEN ISNULL(te.room_type,'')
					ELSE ''
					END  AS [room_type]

				, CASE
					WHEN te.kind_id = @ACCOMM   THEN ISNULL(te.meal_plan,'')
					ELSE ''
					END  AS [meal_plan_code]
				
				, CASE
					WHEN te.kind_id  != @ACCOMM THEN ''
					WHEN te.meal_plan = 'BB'    THEN 'Bed and breakfast'
					WHEN te.meal_plan = 'FB'    THEN 'Full board'
					WHEN te.meal_plan = 'HB'    THEN 'Half board'
					WHEN te.meal_plan = 'RO'    THEN 'Room only'
					ELSE ''
					END  AS [meal_plan]

				-- flight_summary: (Eg: Depart Heathrow on the British Airways flight to Madrid)
				, CASE
					WHEN te.kind_id  != @FLIGHT THEN ISNULL(s.location, '')
					
					ELSE 'Depart '     + ISNULL(ad.name,'')	-- depart_airport
					   + ' on the '    + ISNULL(s.name, '') -- airline
					   + ' flight to ' + ISNULL(aa.name,'')	-- arrive_airport
					   + CASE WHEN arrive_next_day = 1 THEN ' (overnight)' ELSE '' END
					
					END AS [supplier_location]

				-- accommodation_summary: (Eg: Overnight at Hotel das Cataratas on a Bed and breakfast basis)
				, CASE
					WHEN te.kind_id  != @ACCOMM THEN ''
					
					ELSE 'Overnight at '  + ISNULL(s.name, '')
					
					   + CASE WHEN LEN(LTRIM(te.room_type)) > 0
							THEN ' in a ' + te.room_type
							ELSE ''
						 END

					   + CASE
							WHEN LEN(LTRIM(te.meal_plan)) > 0

							THEN ' on a ' + CASE
								WHEN te.meal_plan = 'BB'    THEN 'Bed and breakfast'
								WHEN te.meal_plan = 'FB'    THEN 'Full board'
								WHEN te.meal_plan = 'HB'    THEN 'Half board'
								WHEN te.meal_plan = 'RO'    THEN 'Room only'
								ELSE ''
							END + ' basis'
							
							ELSE ''
						END
		
					END  AS [accommodation_summary]


		FROM trip_elements te
			LEFT JOIN suppliers s ON te.supplier_id = s.id 
			LEFT JOIN airports ad ON te.depart_airport_id = ad.id 
			LEFT JOIN airports aa ON te.arrive_airport_id = aa.id 
		WHERE te.trip_id = @trip_id
			AND ((DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) <= @date
			AND te.end_date > @date) 
			OR (te.end_date < te.start_date AND DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) = @date)) 
			--AND (te.kind_id = 1 OR te.kind_id = 4 OR te.kind_id = 5)
			AND te.kind_id IN( @FLIGHT, @ACCOMM )
		ORDER BY DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0), te.kind_id


	END ELSE BEGIN

		-- When @dummy_day = 1 return a dummy item for populating an empty day:

		SELECT	0 AS [type_id],
				@date AS [display_date],
				@date AS [start_date],
				@date AS [end_date],
				'' AS [supplier_name],
				'' AS [supplier_description],
				'' AS [supplier_image_file],
				'' AS [room_type],
				'' AS [meal_plan_code],
				'' AS [meal_plan],
				'' AS [supplier_location],
				'' AS [accommodation_summary]

	END

END


GO

