USE [steppes2dev]
GO

/****** Object:  StoredProcedure [dbo].[sp_document_data_days]    Script Date: 09/30/2010 14:20:42 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_document_data_days]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_document_data_days]
GO

USE [steppes2dev]
GO

/****** Object:  StoredProcedure [dbo].[sp_document_data_days]    Script Date: 09/30/2010 14:20:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-28
-- Description:	Returns a list of the days in the specified trip
-- Changes:		2010-07-09 - Excluded ground agents from results & refactored with nice readable @ACCOMM variables.
--              2010-09-30 - Now use trip start/end dates instead of finding first and last element dates.
-- =============================================
CREATE PROCEDURE [dbo].[sp_document_data_days]
	@trip_id int
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @FLIGHT  int; SET @FLIGHT  = 1
	DECLARE @HANDLER int; SET @HANDLER = 2
	DECLARE @ACCOMM  int; SET @ACCOMM  = 4
	DECLARE @GROUND  int; SET @GROUND  = 5
	DECLARE @MISC    int; SET @MISC    = 8

	DECLARE @start_date datetime; 
	DECLARE @end_date datetime; 
	
	--SELECT 
	--	@start_date = MIN(start_date) 
	--	, @end_date = MAX(start_date) 
	--FROM trip_elements 
	--	WHERE trip_id = @trip_id 
	--	AND   type_id IN( @FLIGHT, @ACCOMM ) -- Ignore @GROUND
	--GROUP BY trip_id;
	
	-- Fetch trip dates: (instead of element dates above)
	SELECT 
		@start_date = start_date,
		@end_date   = end_date 
	FROM trips
	WHERE id = @trip_id 

	;WITH Dates AS 
	(
		SELECT
 			[Date] = @start_date 
		UNION ALL SELECT 
	 		[Date] = DATEADD(DAY, 1, [Date]) 
		FROM 
			Dates 
		WHERE Date <= @end_date 
	)
	
	SELECT 
		 [Date] AS day_date 
	FROM 
		 Dates 
	OPTION (MAXRECURSION 500)
	
END


GO

