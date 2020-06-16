if  OBJECT_id('tempdb..#TempDBs') is not null 
begin 
drop table #TempDBs
end 


select row_number() over( order by name )Id, name into #TempDBs from sys.databases where name not in ('master'
,'tempdb'
,'model'
,'msdb') and [state]=0
Declare  @query nvarchar(max)
Declare @len  bigint 
Declare @Name  varchar(300)
select @len= count(*) from #TempDBs
while @len>0 
begin
print @len
select @Name=name from #TempDBs where id=@len
set @query =N' use '+@Name
set @query +=N' 
select '''+@name+''' Database_Name, SCHEMA_NAME(schema_id) SchemaName,type_desc objectType,count(*) from sys.objects where is_ms_shipped=0 
group by SCHEMA_NAME(schema_id), type_desc 
--select '''+@name+''' Database_Name,* from sys.tables'
--print @query 
exec sp_executesql @query 
set @len =@len -1
end



