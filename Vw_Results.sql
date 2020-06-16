USE [SQLVulnerabilityAssessment]
GO

/****** Object:  View [dbo].[Vw_Results1]    Script Date: 04-Dec-19 11:32:33 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Script for SelectTopNRows command from SSMS  ******/

CREATE View [dbo].[Vw_Results1]
As

SELECT [Status]
      ,[Risk]
	  ,[ID]
      ,[Server]
      ,[Database]
      ,[Applies to]
      ,[Security Check]
      ,[Description]
      ,[Category]
      ,[Benchmark References]
      ,[Rule Query]
      ,[Actual Result]
      ,[Expected Result]
      ,[Remediation]
      ,[Remediation Script]
	  ,Case  [Risk] When 'High' Then '3'
					When 'Medium' Then '2'
					When 'Low' Then '1'
					Else '0'
		END  As RiskA
	  ,'Panseacorp.com' Domain
	  ,'Production' Environment
  FROM [SQLVulnerabilityAssessment].[dbo].[Tbl_Results]
Where [Server] is not null
GO


