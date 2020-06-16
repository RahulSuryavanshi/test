@echo off
::PLEASE CHANGE THE C:\TEMP\gv$Queries.sql LOCATION TO THE LOCATION WHERE gv$Queries.sql exists
FOR %%A IN (SID1 SID2) DO sqlplus -S username/password@%%A @C:\TEMP\gv$Queries.sql %%A
pause