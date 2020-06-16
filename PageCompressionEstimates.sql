use master
go

set nocount on;

--Run after identifying Specific databases on specific servers

create table #compressionestimates (  servername sysname,  [Database] sysname,  [schema] sysname,  [table] sysname,
	index_no int , [partition] int , IndexSizeKB int, Updates int, Seeks int, Scans int ,row_count int 
	 ,page_est_prc_save float)

create table #objects_with_stats (
	[schema_id] int  , 
	[object_id] int , 
	index_no int ,
	partition int , 
	[Compression] varchar(50), 
	IndexSizeKB bigint ,
	[Updates] int,
	[Seeks] int,
	[Scans] int,
	row_count int
);


--Create a temp table for PAGE compression estimates
create table #estimates_tmp_p (
	[object_name] sysname, 
	[schema_name] sysname, 
	index_id int,
	partition_number int, 
	current_size bigint, 
	estimated_size bigint,
	sample_size bigint,
	sample_estimated bigint
);


DECLARE @dbname AS SYSNAME
DECLARE @sql  AS varchar(max) 
DECLARE [currdbname] CURSOR FOR
SELECT [name] FROM [sys].[databases] where name not in ( 'master','msdb','model', 'tempdb' ) and name not like '%Reportserver%'

OPEN [currdbname]

FETCH NEXT FROM [currdbname] INTO @dbname
WHILE @@fetch_status = 0
BEGIN
--Get the list of the physical objects which are not already compressed in a temp table

	set @sql  =  'USE ' + @dbname + ';' +
		'insert into #objects_with_stats([schema_id], 
			object_id, 
			index_no,
			partition, 
			[Compression], 
			IndexSizeKB,
			[Updates],
			[Seeks],
			[Scans],row_count )
		SELECT distinct [t].schema_id,[p].[object_id],[p].[index_id] index_no,[p].[partition_number] AS [Partition],
			[p].[data_compression_desc] AS [Compression],
			isnull((select SUM(s.[used_page_count]) * 8
			FROM sys.dm_db_partition_stats AS s
			where s.object_id = [p].[object_id] and s.index_id = p.index_id),0) AS IndexSizeKB,
			isnull([u].user_updates,0) + isnull([u].system_updates,0) as [Updates],
			isnull([u].user_seeks,0) + isnull([u].system_seeks,0) as [Seeks],
			isnull([u].user_scans,0) + isnull([u].system_scans,0) as [Scans]
	 ,ddps.row_count 
FROM [sys].[partitions] AS [p]
INNER JOIN sys.tables AS [t] ON [t].[object_id] = [p].[object_id]
INNER JOIN [sys].[indexes] AS i ON i.object_id = p.object_id and i.index_id = p.index_id AND [t].[object_id] = [i].[object_id]
  INNER JOIN sys.objects AS o ON i.OBJECT_ID = o.OBJECT_ID and p.object_id = p.object_id AND [t].[object_id] = [o].[object_id]
  INNER JOIN sys.dm_db_partition_stats AS ddps ON i.OBJECT_ID = ddps.OBJECT_ID
LEFT JOIN sys.dm_db_index_usage_stats AS [u] 
	ON [u].[object_id] = [p].[object_id]
	and [u].[index_id] = [p].[index_id]
WHERE
	[p].[data_compression_desc] <> ''PAGE'' and [p].[data_compression_desc] <> ''COLUMNSTORE'' 
	and i.is_disabled = 0
	and ddps.row_count >10000 

DECLARE @IndexCursor CURSOR;
DECLARE @sch sysname, @tbl sysname, @idx int, @prt int;

SET @IndexCursor = CURSOR FOR
    select distinct SCHEMA_NAME([schema_id]), OBJECT_NAME([object_id]), index_no, Partition from #objects_with_stats;

OPEN @IndexCursor;
FETCH NEXT FROM @IndexCursor INTO @sch, @tbl, @idx, @prt;

WHILE @@FETCH_STATUS = 0
    BEGIN
		if (isnull(@sch,'''') <> '''' and isnull( @tbl ,'''') <> '''')
		Begin
		INSERT INTO #estimates_tmp_p ([object_name], [schema_name], index_id, partition_number, current_size, estimated_size, sample_size, sample_estimated)
		EXEC sp_estimate_data_compression_savings @sch, @tbl, @idx, @prt, ''PAGE'';
		end
		FETCH NEXT FROM @IndexCursor INTO @sch, @tbl, @idx, @prt;
    END; 

CLOSE @IndexCursor;
DEALLOCATE @IndexCursor;

insert into #compressionestimates (servername,[Database],[schema],[table],
	index_no, [partition],IndexSizeKB,Updates,Seeks,Scans,row_count  
	,page_est_prc_save)
select @@Servername servername,DB_NAME()[Database],SCHEMA_NAME(idx.[schema_id]) [schema],OBJECT_NAME(idx.[object_id]) [table],
	idx.index_no,idx.partition,idx.IndexSizeKB,idx.Updates,idx.Seeks,idx.Scans,idx.row_count,pce.page_est_prc_save
from
	#objects_with_stats idx
inner join
	(select OBJECT_ID(''[''+[schema_name]+''].[''+[object_name]+'']'') [object_id], SCHEMA_ID([schema_name]) [schema_id], index_id, partition_number, 
		case when current_size>0 
			then 100.0*(current_size - estimated_size)/current_size 
			else NULL 
		end page_est_prc_save
	from #estimates_tmp_p p) pce
on pce.[schema_id] = idx.[schema_id] and pce.[object_id] = idx.[object_id]
	and pce.index_id = idx.index_no and pce.partition_number = idx.partition'

--print @sql
execute (@sql)

FETCH NEXT FROM [currdbname] INTO @dbname
END

CLOSE [currdbname]
DEALLOCATE [currdbname]

select *,getdate() as CreatedDate From #compressionestimates 
order by [Database], page_est_prc_save desc,row_count desc, IndexSizeKB desc
--Do cleanup
drop table #objects_with_stats
drop table #estimates_tmp_p
drop table #compressionestimates