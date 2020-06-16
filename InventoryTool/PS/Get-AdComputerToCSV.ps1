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
function GetInventoryPs{

$objIsAD  =Get-WindowsFeature -ComputerName omniloadvm -name rsat-ad-powershell
if($objIsAD.InstallState -ne 'Installed') 
{
Install-WindowsFeature -ComputerName omniloadvm -name rsat-ad-powershell
}
#get all ad computer information in a csv file 
$AdComputers = Get-ADComputer -Filter * | Select-Object
#export the computer in the csv file 

#$AdComputers | ConvertTo-Csv -NoTypeInformation | Out-File C:\ADComptersDetails.csv -Encoding utf8 

#export the computer in the csv file 


#Create Cluster object  

$Clusters= Get-Cluster 
$objArray = @()

foreach($cluster in $Clusters)
{
$nodes =Get-ClusterNode -Cluster $cluster

    foreach($node in $nodes)
    {
    $obj = New-Object -TypeName PSObject
    $obj | Add-Member -MemberType NoteProperty  -Name Vname -Value $cluster 
    $obj | Add-Member -MemberType NoteProperty -Name NodeName -Value $node 
    $objArray  += $obj
    }
}


#Create Cluster object  


#$computers = Get-Content -Path 'C:\servernames.txt'

foreach ($ADC in $AdComputers) {
    $Computer=$ADC.Name

    $dnsHost=$ADC.dnsHostname.ToString() 
    $domainName=$dnsHost.Replace( $ADC.Name+".","")

    $Bios = Get-WmiObject win32_bios -Computername $Computer
    $Hardware = Get-WmiObject Win32_computerSystem -Computername $Computer
    $Sysbuild = Get-WmiObject Win32_WmiSetting -Computername $Computer
    $OS = Get-WmiObject Win32_OperatingSystem -Computername $Computer
    $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer | Where-Object {$_.IPEnabled}
    $driveSpace = Get-WmiObject win32_volume -computername $Computer -Filter 'drivetype = 3' | 
    Select-Object PScomputerName, driveletter, label, @{LABEL='GBfreespace';EXPRESSION={'{0:N2}' -f($_.freespace/1GB)} } |
    Where-Object { $_.driveletter -match 'C:' }
    $cpu = Get-WmiObject Win32_Processor  -computername $computer | Select-Object Name,Num* 
    $username = Get-ChildItem "\\$computer\c$\Users" | Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime -first 1
    $totalMemory = [math]::round($Hardware.TotalPhysicalMemory/1024/1024/1024, 2)
    $lastBoot = $OS.ConvertToDateTime($OS.LastBootUpTime) 

    $IPAddress  = $Networks.IpAddress[0]
    $MACAddress  = $Networks.MACAddress
    $systemBios = $Bios.serialnumber

    $checkCluster =$objArray.NodeName.IndexOf($Computer)
    if( $checkCluster -ige 0)
    {
    $IsCluster=1
    $ComputerSystemName =$objArray.Get($checkCluster).Vname
    }
    else
    {
    $ComputerSystemName =$ADC.Name 
    }

    $OutputObj  = New-Object -Type PSObject
    $OutputObj | Add-Member -MemberType NoteProperty -Name NumberOfCores -Value $cpu.NumberOfCores
    $OutputObj | Add-Member -MemberType NoteProperty -Name DeviceNumber -Value $cpu.NumberOfCores
    $OutputObj | Add-Member -MemberType NoteProperty -Name DNSHostName -Value $Computer.ToUpper()#it should be the node name or the servername  
    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerSystemName -Value $ComputerSystemName #it should be the virtual servername or the servername
    $OutputObj | Add-Member -MemberType NoteProperty -Name OperatingSystem -Value $OS.Caption
    $OutputObj | Add-Member -MemberType NoteProperty -Name IsVirtual -Value $Hardware.Model

    $OutputObj | Add-Member -MemberType NoteProperty -Name DomainName -Value $domainName
    $OutputObj | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $Hardware.Manufacturer
    $OutputObj | Add-Member -MemberType NoteProperty -Name Processor_Type -Value $cpu.Name
    $OutputObj | Add-Member -MemberType NoteProperty -Name System_Type -Value $Hardware.SystemType
    $OutputObj | Add-Member -MemberType NoteProperty -Name Operating_System_Version -Value $OS.version
    $OutputObj | Add-Member -MemberType NoteProperty -Name Operating_System_BuildVersion -Value $SysBuild.BuildVersion
    $OutputObj | Add-Member -MemberType NoteProperty -Name Serial_Number -Value $systemBios
    $OutputObj | Add-Member -MemberType NoteProperty -Name IP_Address -Value $IPAddress
    $OutputObj | Add-Member -MemberType NoteProperty -Name MAC_Address -Value $MACAddress
    $OutputObj | Add-Member -MemberType NoteProperty -Name Last_User -Value $username.Name
    $OutputObj | Add-Member -MemberType NoteProperty -Name User_Last_Login -Value $username.LastWriteTime
    $OutputObj | Add-Member -MemberType NoteProperty -Name C:_FreeSpace_GB -Value $driveSpace.GBfreespace
    $OutputObj | Add-Member -MemberType NoteProperty -Name Total_Memory_GB -Value $totalMemory
    $OutputObj | Add-Member -MemberType NoteProperty -Name Number_Of_Logical_Processors -Value $cpu.NumberOfLogicalProcessors
    $OutputObj | Add-Member -MemberType NoteProperty -Name Last_ReBoot -Value $lastboot
    $OutputObj | Export-Csv C:\InventoryDetails.CSV -Append  -NoTypeInformation 

    #get SQl instance information 
   fncGetInstance ( $Computer)

  }


  }

  GetInventoryPs 
#}