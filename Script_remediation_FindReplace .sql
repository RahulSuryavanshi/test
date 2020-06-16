
--=================================================Remediation Automation ======================================================
use Rahul_Test_DMAReporting
if exists ( select * from sys.types where name = 'test')
begin 
drop type test 
end 

create type test as table (id int ,ObjectId bigint ,val nvarchar(max))

declare @CCount bigint

declare @tbl test 
declare @Count int


insert into @tbl 
select row_number()over(order by object_id ) id ,
object_id, definition  
from sys.sql_modules

select @Count=count(*) from @tbl 

while @Count <>0
begin 

select @CCount=count(*) from [master].[dbo].TBL_REMIDIATION_FNRMASTER
declare @query nvarchar(max)
select @query=val  from @tbl where id=@Count
while @CCount<>0
begin 
select  @query=replace(@query,FSTRING,RSTRING) from [master].[dbo].TBL_REMIDIATION_FNRMASTER where id=@ccount
--exec sp_executeSQL @query

set @Count=@Count-1
set @CCount=@CCount-1
end 
print @query 
end 

if exists ( select * from sys.types where name = 'test')
begin 
drop type test 
end 

--=================================================Remediation Automation 12/3/2019======================================================

use master
if exists ( select * from sys.types where name = 'test')
begin 
drop type test 
end 

create type test as table (id int ,ObjectId bigint ,val nvarchar(max))

declare @CCount bigint

declare @tbl test 
declare @Count int

insert into @tbl 
select row_number()over(order by object_id ) id ,
object_id, definition  
from sys.sql_modules

select @Count=count(*) from @tbl 

while @Count <>0
begin 

select @CCount=count(*) from TBL_REMIDIATION_FNRMASTER
declare @query nvarchar(max)
select @query=val  from @tbl where id=@Count
while @CCount<>0
begin 
select  @query=replace(@query,FSTRING,RSTRING) from TBL_REMIDIATION_FNRMASTER where id=@ccount
--exec sp_executeSQL @query

set @Count=@Count-1
set @CCount=@CCount-1
end 
print @query 
end 
