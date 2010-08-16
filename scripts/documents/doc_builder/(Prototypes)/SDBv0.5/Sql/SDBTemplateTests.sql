--
-- STEPPES TEST JOBS--
-- by Nick Casey 2010-04-29
--
-- SQL to add templates and test jobs to the database


--10Brochure_db2.doc
INSERT INTO [Steppes2dev].[dbo].[document_templates]
           ([name]
           ,[file_name]
           ,[document_template_type_id])
     VALUES
           ('10Brochure_db2.doc'
           ,'10Brochure_db2.doc'
           ,1)
GO

INSERT INTO document_jobs (name, document_template_id, [parameters])
VALUES('10BrochureTest', @@Identity, '<job>
   <client_id>21344</client_id>
   <user_id>25</user_id>
</job>')

GO

--10contact_db2.doc
INSERT INTO [Steppes2dev].[dbo].[document_templates]
           ([name]
           ,[file_name]
           ,[document_template_type_id])
     VALUES
           ('10contact_db2.doc'
           ,'10contact_db2.doc'
           ,1)
GO

INSERT INTO document_jobs (name, document_template_id, [parameters])
VALUES('10contactTest', @@Identity, '<job>
   <trip_id>59427</trip_id>
</job>')

GO

--10contact_db2.doc - no accommodation contacts
INSERT INTO [Steppes2dev].[dbo].[document_templates]
           ([name]
           ,[file_name]
           ,[document_template_type_id])
     VALUES
           ('10contact_db2.doc'
           ,'10contact_db2.doc'
           ,1)
GO

INSERT INTO document_jobs (name, document_template_id, [parameters])
VALUES('10contact-noaccommTest', @@Identity, '<job>
   <trip_id>501</trip_id>
</job>')

GO

--10invoice_db2.doc 
INSERT INTO [Steppes2dev].[dbo].[document_templates]
           ([name]
           ,[file_name]
           ,[document_template_type_id])
     VALUES
           ('10invoice_db2.doc'
           ,'10invoice_db2.doc'
           ,1)
GO

INSERT INTO document_jobs (name, document_template_id, [parameters])
VALUES('10invoiceTest', @@Identity, '<job>
	<invoice_id>13496</invoice_id>
	</job>')

GO

--10itinerary_db2.doc
INSERT INTO [Steppes2dev].[dbo].[document_templates]
           ([name]
           ,[file_name]
           ,[document_template_type_id])
     VALUES
           ('10itinerary_db2.doc'
           ,'10itinerary_db2.doc'
           ,1)
GO

INSERT INTO document_jobs (name, document_template_id, [parameters])
VALUES('10itineraryTest', @@Identity, '<job>
	<trip_id>17</trip_id>
	<user_id>48</user_id>
	</job>')

GO

--10NonATOLInvoice_db2.doc
INSERT INTO [Steppes2dev].[dbo].[document_templates]
           ([name]
           ,[file_name]
           ,[document_template_type_id])
     VALUES
           ('10NonATOLInv_db2.doc'
           ,'10NonATOLInv_db2.doc'
           ,1)
GO

INSERT INTO document_jobs (name, document_template_id, [parameters])
VALUES('10NonATOLInvoiceTest', @@Identity, '<job>
	<invoice_id>13496</invoice_id>
	</job>')

GO

--10AlaskaCLet_db2.doc2.doc
INSERT INTO [Steppes2dev].[dbo].[document_templates]
           ([name]
           ,[file_name]
           ,[document_template_type_id])
     VALUES
           ('10AlaskaCLet_db2.doc'
           ,'10AlaskaCLet_db2.doc'
           ,1)
GO

INSERT INTO document_jobs (name, document_template_id, [parameters])
VALUES('10AlaskaCLetTest', @@Identity, '<job>
	<trip_id>59427</trip_id>
	<client_id>2138546782</client_id>
	</job>')

GO

--10AlaskaFLet_db2.doc2.doc
INSERT INTO [Steppes2dev].[dbo].[document_templates]
           ([name]
           ,[file_name]
           ,[document_template_type_id])
     VALUES
           ('10AlaskaFLet_db2.doc'
           ,'10AlaskaFLet_db2.doc'
           ,1)
GO

INSERT INTO document_jobs (name, document_template_id, [parameters])
VALUES('10AlaskaFLetTest', @@Identity, '<job>
	<trip_id>59427</trip_id>
	<client_id>2138546782</client_id>
	</job>')

GO

--10WelHomeLet_db2.doc2.doc
INSERT INTO [Steppes2dev].[dbo].[document_templates]
           ([name]
           ,[file_name]
           ,[document_template_type_id])
     VALUES
           ('10WelHomeLet_db2.doc'
           ,'10WelHomeLet_db2.doc'
           ,1)
GO

INSERT INTO document_jobs (name, document_template_id, [parameters])
VALUES('10WelHomeLetTest', @@Identity, '<job>
	<trip_id>59427</trip_id>
	<client_id>2138546782</client_id>
	</job>')

GO

--select * from document_jobs
--select * from trips
--select * from trip_clients where trip_id = 59427
--select * from clients where id = 2138546782
--select * from users
--select * from money_ins
--select * from suppliers
