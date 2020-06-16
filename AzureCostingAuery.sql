
-----------------------------------All candidates for Azure costing 
drop table #temp
select inv.DeviceNumber,[Clustered],inv.DnsHostName,InstanceName,Vsname,Skuname,[Version],DBP.ServerName,DBP.DbName,DBP.Size ,
 DVC.DomainName,DVC.AdDnsHostName,DVC.AdFullyQualifiedDomainName,DVC.NumberOfCores,DVC.NumberOfLogicalProcessors,DVC.NumberOfProcessors
,DVC.OperatingSystem,DashboardAnalysis.dbo._ConvertToGB(DVC.TotalVirtualMemorySize)TotalVirtualMemorySize,
DashboardAnalysis.dbo._ConvertToGB(DVC.TotalVisibleMemorySize)TotalVisibleMemorySize,DashboardAnalysis.dbo._ConvertToGB(DVC. TotalPhysicalMemory) TotalPhysicalMemory,
MT.MetricName,MetricMax,MetricMin,MetricAvg,MetricPercentile  into #temp from
(select distinct [InstanceName]  ServerName  from BlueScope_DMAReporting.[dbo].[ReportData] UC 
 UNION
 select   [ServerName] FROM   BlueScope_DMAReporting.[dbo].[AzureFeatureParity] ) srvr inner join Discovery. SqlServer_Inventory.Inventory  inv 
on case when CHARINDEX('.', srvr.ServerName) > 0 then replace(srvr.ServerName, SUBSTRING(srvr.ServerName,CHARINDEX('.', srvr.ServerName),case when CHARINDEX('\', srvr.ServerName) >0 then  CHARINDEX('\', srvr.ServerName)-CHARINDEX('.', srvr.ServerName) else len(srvr.ServerName)-CHARINDEX('.', srvr.ServerName)+1 end ),'')  else srvr.ServerName end
=case when InstanceName = 'MSSQLSERVER'  then DnsHostName else DnsHostName+'\'+InstanceName end and inv.Sqlservicetype=1
left join Discovery.SqlServer_Inventory.DataBaseProperties DBP on INV.DeviceNumber=DBP.DeviceNumber
left join Discovery.Core_Inventory.Devices DVC on  inv.DeviceNumber =DVC.DeviceNumber
inner join Discovery.Perf_Assessment.MetricAggregation MA on  inv.DeviceNumber =MA.DeviceNumber 
inner join Discovery.Perf_Inventory.[MetricTypes] MT on MA.MetricType=MT.MetricType
where DBP.DbName not in ('master','model','msdb','tempdb')

--------------------------PAAS sizing result set need to group dtabases in elastic pools 
select Distinct DeviceNumber,DnsHostName,count(DbName) DBCount,sum( convert(decimal,ltrim(rtrim(replace(size,'MB','')))) )/1024 sizeGB  into #PAAS from 
(select distinct DeviceNumber,DnsHostName,InstanceName,dbname, size from #temp 
)T
group by DeviceNumber,DnsHostName,InstanceName

select * from #PAAS
--------------------------IAAS and MI Costing 
--select distinct avgData.DeviceNumber, avgData.DnsHostName,avgData.InstanceName,avgData.NumberOfCores,avgData.NumberOfLogicalProcessors,avgData.NumberOfProcessors,avgData.TotalPhysicalMemory 
--,avgData.cpu_percentage,maxData.cpu_percentage Max_cpu_percentage,avgData.[diskiops_total],maxData.diskiops_total Max_diskiops_total,avgData.[diskspace_gb_used],maxData.diskspace_gb_used Max_diskspace_gb_used,avgData.memory_gb_used
--,maxData.memory_gb_used Max_memory_gb_used
select * into #avg
from (
select * from (
select Distinct  DeviceNumber,DnsHostName,InstanceName,NumberOfCores,NumberOfLogicalProcessors,NumberOfProcessors,TotalPhysicalMemory
,MetricName,MetricAvg 
from #temp
where MetricName in (
'cpu_percentage'
,'diskiops_total'
,'diskspace_gb_used'
,'memory_gb_used'
)
)T 
pivot
(
avg (MetricAvg ) for MetricName in ([cpu_percentage],[diskiops_total],[diskspace_gb_used],[memory_gb_used])
) PVTAvg
)avgData

select distinct DeviceNumber from #AVG
-------------------------------------------------------------
select * into #Max
from (
select Distinct  DeviceNumber,DnsHostName,InstanceName,NumberOfCores,NumberOfLogicalProcessors,NumberOfProcessors,TotalPhysicalMemory
,MetricName,MetricMax 
from #temp
where MetricName in (
'cpu_percentage'
,'diskiops_total'
,'diskspace_gb_used'
,'memory_gb_used'
)
)T 
pivot
(
avg (MetricMax ) for MetricName in ([cpu_percentage],[diskiops_total],[diskspace_gb_used],[memory_gb_used])
) PVTmax

select  DnsHostName,InstanceName from #Max
select * from 
(select distinct [InstanceName]  ServerName  from BlueScope_DMAReporting.[dbo].[ReportData] UC 
 UNION
 select   [ServerName] FROM   BlueScope_DMAReporting.[dbo].[AzureFeatureParity] ) srvr
 where not exists ( select 1 from #Max a where a.DnsHostName+'\'+a.InstanceName = srvr.ServerName)