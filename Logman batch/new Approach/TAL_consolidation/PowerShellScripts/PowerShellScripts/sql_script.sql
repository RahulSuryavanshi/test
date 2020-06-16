SET NOCOUNT ON
GO
USE MASTER
GO
SELECT CONVERT (varchar, GETDATE(), 109) AS [--- WHEN SCRIPT RAN ---]
SELECT 'SERVICE RUNNING FOR '+ 
	CAST((DATEDIFF(hh, crdate, GETDATE()))/24 AS VARCHAR(3)) + ' days,  '+ 
	CAST((DATEDIFF(hh, crdate, GETDATE())) % 24 AS VARCHAR(2)) + ' hours' AS [LAST RESTART DATE]
	FROM MASTER..sysdatabases WHERE name = 'tempdb'
SELECT @@SERVERNAME AS [--- SERVER NAME ---]
SELECT @@VERSION AS [--- SERVER VERSION ---];
GO
SET QUOTED_IDENTIFIER OFF 
SET ANSI_NULLS OFF 
GO
SELECT CONVERT(char(20), SERVERPROPERTY ('ProductLevel')) AS ProductLevel
SELECT CONVERT(char(20), SERVERPROPERTY ('ProductVersion')) AS ProductVersion
SELECT CONVERT(char(20), SERVERPROPERTY ('Edition')) AS Edition
SELECT CONVERT(char(20), SERVERPROPERTY ('Engine Edition')) AS EditionEngine
SELECT CONVERT(char(20), SERVERPROPERTY ('InstanceName')) AS InstanceName
SELECT CONVERT(char(50), SERVERPROPERTY ('Collation')) AS Collation
SELECT CONVERT(char(20), SERVERPROPERTY ('IsClustered')) AS IsClustered
SELECT CONVERT(char(20), SERVERPROPERTY ('IsFullTextInstalled')) AS IsFullTextInstalled
SELECT CONVERT(char(20), SERVERPROPERTY ('IsIntegratedSecurityOnly')) AS IsIntegratedSecurityOnly
SELECT CONVERT(char(20), SERVERPROPERTY ('IsSingleUser')) AS IsSingleUser
SELECT CONVERT(char(20), SERVERPROPERTY ('IsSyncWithBackup')) AS IsSyncWithBackup
SELECT CONVERT(char(20), SERVERPROPERTY ('LicenseType')) AS LicenseType
SELECT CONVERT(char(20), SERVERPROPERTY ('NumLicenses')) AS NumLicenses
SELECT CONVERT(char(20), SERVERPROPERTY ('ProcessID')) AS ProcessID
SELECT CONVERT(char(20), SERVERPROPERTY ('RecoveryModel')) AS [Recovery Model];
GO
SELECT 'FOR 2005 and HIGHER' AS [RECOVERY MODEL, LOG REUSE WAIT DESCRIPTION, LOG FILE SIZE, LOG USAGE SIZE];
SELECT db.[name] AS [Database Name], db.recovery_model_desc AS [Recovery Model], 
db.log_reuse_wait_desc AS [Log Reuse Wait Description], 
ls.cntr_value AS [Log Size (KB)], lu.cntr_value AS [Log Used (KB)],
CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)AS DECIMAL(18,2)) * 100 AS [Log Used %], 
db.[compatibility_level] AS [DB Compatibility Level], 
db.page_verify_option_desc AS [Page Verify Option], db.is_auto_update_stats_on,
db.is_auto_update_stats_async_on, db.is_parameterization_forced, db.is_supplemental_logging_enabled, 
db.snapshot_isolation_state_desc, db.is_read_committed_snapshot_on
FROM sys.databases AS db
INNER JOIN sys.dm_os_performance_counters AS lu 
ON db.name = lu.instance_name
INNER JOIN sys.dm_os_performance_counters AS ls 
ON db.name = ls.instance_name
WHERE lu.counter_name LIKE N'Log File(s) Used Size (KB)%' 
AND ls.counter_name LIKE N'Log File(s) Size (KB)%'
AND ls.cntr_value > 0;
GO
SELECT '' AS [DBCC USEROPTIONS]
DBCC UserOptions
GO
SELECT 'SYSCONFIGURES ONLY FOR SQL 2005 and HIGHER' AS [SP_CONFIGURE ALTERNATIVE];
SELECT name, value, value_in_use FROM sys.configurations;
GO
SELECT 'ARE THERE ANY "ACTIVE"' AS [TRACE FLAGS?]
DBCC TRACESTATUS(-1) WITH NO_INFOMSGS;
GO
SELECT 'LOOK FOR "SQLARG3" OR HIGHER' AS [ARE THERE ANY STARTUP PARAMTERS?]
EXEC master..xp_instance_regenumvalues 'HKEY_LOCAL_MACHINE', 
  'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\Parameters'
GO
SELECT 'GENERAL DATABASE PROPERTIES' AS [SYS.DATABASES];
SELECT * FROM master.sys.databases ORDER BY database_id;
GO
SELECT 'FOR SQL 2008 AND HIGHER' ;
SELECT '    ARE LOCKED & LARGE PAGES ENABLED?' AS [SQL SERVER PROCESS ADDRESS SPACE INFO];
SELECT * FROM sys.dm_os_process_memory;
GO
SELECT '(CANNOT DISTINGUISH BETWEEN HT AND MULTI-CORE)' AS [ LOGICAL_CPUS ];
GO
SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count], 
physical_memory_in_bytes/1048576 AS [Physical Memory (MB)]
FROM sys.dm_os_sys_info;
GO
SELECT '' AS [PROCESSOR INFO];
EXEC master..xp_instance_regenumvalues 'HKEY_LOCAL_MACHINE', 
  'HARDWARE\DESCRIPTION\System\CentralProcessor\0'
GO
SELECT 'Msg 22001 JUST MEANS NO IS THE ANSWER' AS [IS SOFT NUMA CONFIGURED?];
EXEC master..xp_instance_regenumvalues 'HKEY_LOCAL_MACHINE', 
  'SOFTWARE\Microsoft\\Microsoft SQL Server\100\NodeConfiguration\Node0'
GO
SELECT 'FROM SP_HELPSERVER' AS [SERVER NAMES];
EXEC master..sp_helpserver;
GO
SELECT '' AS [COLLATION, SORT-ORDER, CASE SENSITIVITY?];
EXEC sp_server_info @attribute_id = '18';
SELECT @@LANGUAGE AS  [WHAT LANGUAGE IS INSTALLED?];
GO
SELECT 'SYSALTFILES' AS [THE FOLLOWING SECTION IS ABOUT IO AND DISK INFO];
SELECT * FROM master.sys.sysaltfiles;
GO
SET QUOTED_IDENTIFIER OFF 
SET ANSI_NULLS OFF 
GO
SELECT 'NO DATA AFTER DRIVENAME MEANS NOT CLUSTERED' AS [FN_SERVERSHAREDDRIVES - NAMES OF SHARED DRIVES USED BY THE CLUSTERED SERVER]
SELECT * FROM ::fn_servershareddrives();
GO
SELECT 'NO DATA AFTER NODENAME MEANS NOT CLUSTERED' AS [FN_VIRTUALSERVERNODES - NODE NAMES FOR VIRTUAL SQL SERVER ON CLUSTERED SERVER];
SELECT * FROM ::fn_virtualservernodes();
GO
SELECT '' AS [LIST FIXED DRIVES];
EXEC xp_fixeddrives;
GO







