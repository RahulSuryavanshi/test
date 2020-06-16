function fncGetInstance 
{

Param  ([string] $machine)
 #$Machines  = "node1","node2","sqlcluster2016","winad"
 #$Machines | Add-Member -MemberType NoteProperty -Value "Node1"
 #$Machines | Add-Member -MemberType NoteProperty -Name InstanceName -Value "Node2"
 #$Machines | Add-Member -MemberType NoteProperty -Name InstanceName -Value "winad"
 #$Machines | Add-Member -MemberType NoteProperty -Name InstanceName -Value "sqlcluster2012"
 
 Write-Host $Messahe -ForegroundColor Green
 #foreach($machine in $Machines)
 #{
 
$sqlInstances=  get-service -computername $machine  | where {$_.Name -like 'mssql$mssqlserver*' -or $_.Name -eq 'MSSQLSERVER' } | select-object Name,Status,Machinename
foreach($sqlInstance in $sqlInstances)
{
if($sqlInstance.Name  -like 'MSSQL$MSSQLSERVER*' )
{
$sqlInstancesActual= $sqlInstance.Name.Tostring().Replace("MSSQL$",$sqlInstance.MachineName.Tostring()+"/")
}
else
{
$sqlInstancesActual= $sqlInstance.Name.Tostring().Replace("MSSQLSERVER",$sqlInstance.MachineName.Tostring())
}


$OutputSqlInstance  = New-Object -Type PSObject
$OutputSqlInstance | Add-Member -MemberType NoteProperty -Name Name -Value $sqlInstance.Name
$OutputSqlInstance | Add-Member -MemberType NoteProperty -Name Status -Value $sqlInstance.Status
$OutputSqlInstance | Add-Member -MemberType NoteProperty -Name Machinename -Value $sqlInstance.MachineName
$OutputSqlInstance | Add-Member -MemberType NoteProperty -Name InstanceNameModified -Value $sqlInstancesActual
$OutputSqlInstance | Export-Csv C:\SQLInstance.CSV -Append  -NoTypeInformation 

}

#} 
}