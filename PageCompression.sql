USE AdventureWorks2012;  
GO  
EXEC sp_estimate_data_compression_savings 'Production', 'TransactionHistory', NULL, NULL, 'ROW' ;  

--ALTER TABLE Production.TransactionHistory REBUILD PARTITION = ALL  
--WITH (DATA_COMPRESSION = ROW);   
--GO

USE AdventureWorks2012;  
GO  
EXEC sp_estimate_data_compression_savings 'Production', 'TransactionHistoryArchive', NULL, NULL, 'Page' ;  



--ALTER TABLE Production.TransactionHistoryArchive REBUILD PARTITION = ALL  
--WITH (DATA_COMPRESSION = PAGE);   
--GO