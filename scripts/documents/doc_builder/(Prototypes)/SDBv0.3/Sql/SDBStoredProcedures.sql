USE [Steppes2dev]
GO
/****** Object:  StoredProcedure [dbo].[sp_document_data_trip]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE [sp_document_data_trip]
DROP PROCEDURE [sp_document_data_client]
DROP PROCEDURE [sp_document_data_flights]
DROP PROCEDURE [sp_document_data_days]
DROP PROCEDURE [sp_document_data_accommodation]
DROP PROCEDURE [sp_document_data_ground_elements]
DROP PROCEDURE [sp_document_data_day_elements]
DROP PROCEDURE [sp_document_data_user]
DROP PROCEDURE [sp_document_job_parameters]
DROP PROCEDURE [sp_document_update_job_status]
DROP PROCEDURE [sp_document_data_invoice]
GO

-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-28
-- Description:	Returns trip data for the specified trip
-- =============================================
CREATE PROCEDURE [sp_document_data_trip]
	@id int
AS
BEGIN

	SET NOCOUNT ON;

	SELECT t.*  
		, tv1.name AS [title] 
		, ISNULL((SELECT TOP 1 a.name FROM trip_elements te 
			LEFT JOIN airports a ON te.depart_airport_id = a.id 
		WHERE te.type_id = 1 
			AND te.trip_id = t.id 
		ORDER BY te.start_date), '') AS first_flight_depart_airport_name
		, ISNULL((SELECT STUFF(( SELECT DISTINCT ', ' + cl.fullname 
			FROM trip_clients tc 
			LEFT JOIN clients cl 
			ON tc.client_id = cl.id 
			WHERE tc.trip_id = t.id 
			FOR XML PATH('')), 1, 1, '')), '') 
			AS client_names 
		, ISNULL((SELECT STUFF(( SELECT DISTINCT ', ' + [name] 
			FROM trip_countries tc  
			LEFT JOIN countries c  
			ON c.id = tc.country_id 
			WHERE tc.trip_id = t.id 
			FOR XML PATH('')), 1, 1, '')), '')  
		  AS countries 
		, REPLACE(REPLACE(ISNULL((SELECT STUFF(( SELECT DISTINCT CHAR(10) + CHAR(10) + inclusions 
			FROM trip_countries tc  
			LEFT JOIN countries c  
			ON c.id = tc.country_id 
			WHERE tc.trip_id = t.id 
			FOR XML PATH('')), 1, 1, '')), ''), '&#x0D;', ''), '&#x0A;', '')  
		  AS countries_inclusions 
		, REPLACE(REPLACE( ISNULL((SELECT STUFF(( SELECT DISTINCT CHAR(10) + CHAR(10) + exclusions 
			FROM trip_countries tc  
			LEFT JOIN countries c  
			ON c.id = tc.country_id 
			WHERE tc.trip_id = t.id 
			FOR XML PATH('')), 1, 1, '')), ''), '&#x0D;', ''), '&#x0A;', '')  
		  AS countries_exclusions 
		, REPLACE(REPLACE( ISNULL((SELECT STUFF(( SELECT DISTINCT CHAR(10) + CHAR(10) + notes 
			FROM trip_countries tc  
			LEFT JOIN countries c  
			ON c.id = tc.country_id 
			WHERE tc.trip_id = t.id 
			FOR XML PATH('')), 1, 1, '')), ''), '&#x0D;', ''), '&#x0A;', '')  
		  AS countries_notes 
		FROM trips t 
	LEFT JOIN trips tv1 ON t.version_of_trip_id = tv1.id  
	WHERE t.id = @id
END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_data_client]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-28
-- Description:	Returns client data for specified client
-- =============================================
CREATE PROCEDURE [sp_document_data_client]
	@id int
AS
BEGIN

	SET NOCOUNT ON;

	SELECT * 
			, CASE WHEN ISNULL(address1, '') = '' THEN '' ELSE address1 + CHAR(10) END 
			+ CASE WHEN ISNULL(address2, '') = '' THEN '' ELSE address2 + CHAR(10) END 
			+ CASE WHEN ISNULL(address3, '') = '' THEN '' ELSE address3 + CHAR(10) END 
			+ CASE WHEN ISNULL(address4, '') = '' THEN '' ELSE address4 + CHAR(10) END 
			+ CASE WHEN ISNULL(address5, '') = '' THEN '' ELSE address5 + CHAR(10) END 
			+ CASE WHEN ISNULL(address6, '') = '' THEN '' ELSE address6 + CHAR(10) END 
			+ CASE WHEN ISNULL(postcode, '') = '' THEN '' ELSE postcode + CHAR(10) END 
			+ CASE WHEN ISNULL(b.country_id, 0) = 0 THEN '' ELSE co.[name] + CHAR(10) END 
			AS [address] 
		FROM clients c 
		INNER JOIN ( 
			SELECT 
				ca.client_id 
				, a.*  
			FROM client_addresses ca 
				INNER JOIN addresses a ON ca.address_id = a.id 
			WHERE is_active = 1  
		) b ON c.id = b.client_id 
			LEFT JOIN countries co ON co.id = b.country_id 
			WHERE c.id= @id
			
END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_data_flights]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-28
-- Description:	Returns a list of flights for the specified trip
-- =============================================
CREATE PROCEDURE [sp_document_data_flights]
	@trip_id int
AS
BEGIN

	SET NOCOUNT ON;

    SELECT 
		te.start_date 
		, te.end_date 
		, ISNULL(te.flight_code , '') AS [flight_code]
		, ISNULL(s.name , '')  AS [airline]
		, ISNULL(ad.name , '')  AS [depart_airport_name]
		, ISNULL(aa.name , '')  AS [arrive_airport_name]
		, CASE WHEN arrive_next_day = 1 THEN '*' ELSE '' END AS [arrive_next_day] 
		, DATEADD(hour
				, -ISNULL( ( SELECT CAST(value AS int) 
								FROM app_settings 
								WHERE name = 'check_in_period' 
								AND ISNUMERIC(value)=1 ), 2 )  -- Default to 2 hours when app_setting missing
				,start_date 
		) AS [check_in_date]
	FROM trip_elements te 
		LEFT JOIN suppliers s ON te.supplier_id = s.id 
		LEFT JOIN airports ad ON te.depart_airport_id = ad.id 
		LEFT JOIN airports aa ON te.arrive_airport_id = aa.id 
	WHERE te.trip_id = @trip_id
		AND te.type_id = 1 
	ORDER BY te.start_date
END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_data_days]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-28
-- Description:	Returns a list of the days in the specified trip
-- =============================================
CREATE PROCEDURE [sp_document_data_days]
	@trip_id int
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @start_date datetime; 
	DECLARE @end_date datetime; 
	
	SELECT 
		@start_date = MIN(start_date) 
		, @end_date = MAX(start_date) 
	FROM trip_elements 
		WHERE trip_id = @trip_id 
		AND (type_id = 1 
			OR type_id = 4 
			OR type_id = 5)
	GROUP BY trip_id;
	
	WITH Dates AS 
	(
		SELECT
 			[Date] = @start_date 
		UNION ALL SELECT 
	 		[Date] = DATEADD(DAY, 1, [Date]) 
		FROM 
			Dates 
		WHERE Date <= @end_date 
	)SELECT 
		 [Date] AS day_date 
	FROM 
		 Dates 
	OPTION (MAXRECURSION 400)
	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_data_ground_elements]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-29
-- Description:	Returns a list of ground elements for the specified trip
-- =============================================
CREATE PROCEDURE [sp_document_data_ground_elements]
	@trip_id int
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT te.type_id
			, te.name as [name]
			, te.start_date
			, te.end_date
			, ISNULL(s.name, '') AS [supplier_name]
			, (CASE WHEN ISNULL(address1, '') = '' THEN '' ELSE address1 + CHAR(10) END
				+ CASE WHEN ISNULL(address2, '') = '' THEN '' ELSE address2 + CHAR(10) END
				+ CASE WHEN ISNULL(address3, '') = '' THEN '' ELSE address3 + CHAR(10) END
				+ CASE WHEN ISNULL(address4, '') = '' THEN '' ELSE address4 + CHAR(10) END
				+ CASE WHEN ISNULL(address5, '') = '' THEN '' ELSE address5 + CHAR(10) END
				+ CASE WHEN ISNULL(address6, '') = '' THEN '' ELSE address6 + CHAR(10) END
				+ CASE WHEN ISNULL(postcode, '') = '' THEN '' ELSE postcode + CHAR(10) END
				+ CASE WHEN ISNULL(a.country_id, 0) = 0 THEN '' ELSE c.[name] END
				) AS [supplier_address]
			, ISNULL(a.tel_home, '') AS [supplier_tel_home]
			, ISNULL(a.fax_home, '') AS [supplier_fax_home]
			, ISNULL(s.tel_emergency, '') AS [supplier_tel_emergency]
			, ISNULL(s.email, '') AS [supplier_email]
			, ISNULL(s.contact_name, '') AS [supplier_contact_name]
			, ISNULL(s.contact_name2, '') AS [supplier_contact_name2]
	FROM trip_elements te
		LEFT JOIN suppliers s ON te.supplier_id = s.id
		LEFT JOIN addresses a ON s.address_id = a.id
		LEFT JOIN countries c ON a.country_id = c.id
	WHERE te.trip_id = @trip_id
		AND te.type_id = 5 
	ORDER BY te.start_date
    
END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_data_accommodation]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-29
-- Description:	Returns list of accomodation for specified trip
-- =============================================
CREATE PROCEDURE [sp_document_data_accommodation]
	@trip_id int
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT te.type_id
			, te.name as [name]
			, te.start_date
			, te.end_date
			, ISNULL(s.name, '') AS [supplier_name]
			, (CASE WHEN ISNULL(address1, '') = '' THEN '' ELSE address1 + CHAR(10) END
				+ CASE WHEN ISNULL(address2, '') = '' THEN '' ELSE address2 + CHAR(10) END
				+ CASE WHEN ISNULL(address3, '') = '' THEN '' ELSE address3 + CHAR(10) END
				+ CASE WHEN ISNULL(address4, '') = '' THEN '' ELSE address4 + CHAR(10) END
				+ CASE WHEN ISNULL(address5, '') = '' THEN '' ELSE address5 + CHAR(10) END
				+ CASE WHEN ISNULL(address6, '') = '' THEN '' ELSE address6 + CHAR(10) END
				+ CASE WHEN ISNULL(postcode, '') = '' THEN '' ELSE postcode + CHAR(10) END
				+ CASE WHEN ISNULL(a.country_id, 0) = 0 THEN '' ELSE c.[name] END
				) AS [supplier_address]
			, ISNULL(a.tel_home, '') AS [supplier_tel_home]
			, ISNULL(a.fax_home, '') AS [supplier_fax_home]
			, ISNULL(s.tel_emergency, '') AS [supplier_tel_emergency]
			, ISNULL(s.email, '') AS [supplier_email]
			, ISNULL(s.contact_name, '') AS [supplier_contact_name]
			, ISNULL(s.contact_name2, '') AS [supplier_contact_name2]
	FROM trip_elements te
		LEFT JOIN suppliers s ON te.supplier_id = s.id
		LEFT JOIN addresses a ON s.address_id = a.id
		LEFT JOIN countries c ON a.country_id = c.id
	WHERE te.trip_id = @trip_id
		AND te.type_id = 4 
	ORDER BY te.start_date
    
END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_data_day_elements]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-28
-- Description:	Returns list of elements for a particular day in the specified trip
-- =============================================
CREATE PROCEDURE [sp_document_data_day_elements]
	@trip_id int
	,@date smalldatetime
AS
BEGIN

	SET NOCOUNT ON;

	SELECT te.type_id
			, @date AS [display_date]
			, te.start_date
			, te.end_date
			, ISNULL(s.name, '') AS [supplier_name]
			, CASE WHEN te.type_id = 1 
					THEN 'Fly ' + ad.name + '/' + aa.name + CASE WHEN arrive_next_day = 1 
																THEN ' (overnight)' 
																ELSE '' 
																END 
					ELSE ISNULL(s.location, '') 
					END AS [supplier_location]
			, CASE WHEN DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) = @date
					THEN ISNULL(s.description,'') 
					ELSE '' 
					END AS [supplier_description] 
			, CASE WHEN DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) = @date
					THEN ISNULL(s.image_file,'') 
					ELSE '' 
					END AS [supplier_image_file] 
	FROM trip_elements te
		LEFT JOIN suppliers s ON te.supplier_id = s.id 
		LEFT JOIN airports ad ON te.depart_airport_id = ad.id 
		LEFT JOIN airports aa ON te.arrive_airport_id = aa.id 
	WHERE te.trip_id = @trip_id
		AND ((DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) <= @date
		AND te.end_date > @date) 
		OR (te.end_date < te.start_date AND DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0) = @date)) 
		AND (te.type_id = 1 OR te.type_id = 4 OR te.type_id = 5) 
	ORDER BY DATEADD(Day, DATEDIFF(Day, 0, te.start_date), 0), te.type_id

END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_data_user]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-28
-- Description:	Returns user data for the specified user
-- =============================================
CREATE PROCEDURE [sp_document_data_user]
	@id int
AS
BEGIN
	SET NOCOUNT ON;

	SELECT u.* 
			, c.name AS [company_name]
	FROM users u
		INNER JOIN companies c ON u.company_id = c.id
	WHERE u.id = @Id
	
	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_job_parameters]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-29
-- Description:	Gets the parameters for the specified job
-- =============================================
CREATE PROCEDURE [sp_document_job_parameters]
	@job_id int
AS
BEGIN
	
	SET NOCOUNT ON;

   	SET ANSI_PADDING ON;
	SELECT dt.[file_name] AS [template_name]
			, dj.[name] AS [document_name]
			, [parameters].query('data(//client_id)') AS [client_id]
			, [parameters].query('data(//trip_id)') AS [trip_id]	
			, [parameters].query('data(//user_id)') AS [user_id]
			, [parameters].query('data(//invoice_id)') AS [invoice_id]	
			, [parameters].query('data(//voucher_id)') AS [voucher_id]
	FROM document_jobs dj 
			INNER JOIN document_templates dt
			ON dj.document_template_id = dt.id 	
	WHERE dj.id = @job_id;
	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_update_job_status]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-29
-- Description:	Updates the status for the specified job
-- =============================================
CREATE PROCEDURE [sp_document_update_job_status]
	@job_id int
	, @status int
AS
BEGIN
	
	SET NOCOUNT ON;

   	UPDATE document_jobs 
   	SET document_status_id= @status
		WHERE id = @job_id;
	
END
GO
/****** Object:  StoredProcedure [dbo].[sp_document_data_invoice]    Script Date: 04/30/2010 09:44:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Nick Casey
-- Create date: 2010-04-28
-- Description:	Returns invoice data for the specified invoice
-- =============================================
CREATE PROCEDURE [sp_document_data_invoice]
	@id int
AS
BEGIN

	SET NOCOUNT ON;

    SELECT 
		mi.name AS [number]
		, mi.amount as [balance_amount]
		, mi.*
		, mid.amount as [deposit_amount]
	FROM money_ins mi
	LEFT JOIN money_ins mid ON mi.name = mid.name --assumes only one is_deposit for particular invoice name
	WHERE mid.is_deposit = 1
		AND mi.id = @id
END
GO
