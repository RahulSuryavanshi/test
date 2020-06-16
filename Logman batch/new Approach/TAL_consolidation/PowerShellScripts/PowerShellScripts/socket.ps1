# getSQLInfo.ps1
# Pings a list of servers contained in the text file servers.txt and if the server responds, returns WMI and SQL Server information from each server
#
# Change log:
# May 3, 2011: Yogesh Bhalerao
#   Updated to also add exception handling
#   Changed Write-Host to Write-Output
# April 15, 2011: Yogesh Bhalerao
#   Updated to also add IP address in the servers.txt
# January 10, 2011: Yogesh Bhalerao
#   Initial Version
#
# Notes: To determine if hyperthreading is enabled for the processor, compare NumberOfLogicalProcessors and NumberOfCores. 
#        If hyperthreading is enabled in the BIOS for the processor, then NumberOfCores is less than NumberOfLogicalProcessors.
#        For example, a dual-processor system that contains two processors enabled for hyperthreading can run four threads or programs
#        or simultaneously. In this case, NumberOfCores is 2 and NumberOfLogicalProcessors is 4.
#


[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
# Replace "C:\Users\ybhalerao\Documents\Project\Others\Test" with the actual root folder on the central server
# Note: Do not add the "\" at the end of the root folder
$mainFolder  = "C:\Projects\EPCO"

#
# D O    N O T    M O D I F Y    B E L O W    T H I S    L I N E
#

$scriptsFolder  = $mainFolder + "\PowershellScripts\"
$serversFile = $scriptsFolder + "servers.txt"
$serversNotResponding = $scriptsFolder + "serversnotresponding.txt"

$dataFolder  = $mainFolder + "\Data\"

$serverNameLine     = Get-Content -Path $serversFile
$servernameline

foreach ($serverLine in $serverNameLine)
{
    trap [Exception] {
        Write-Output "........Some exception? $_"
        continue
    }

    $ipaddress = ""
    $port = ""
    $serverName = $serverLine
    if ($serverLine -match "\,") {
        $serverSplit  = $serverLine.Split(",")
        foreach ($element in $serverSplit) 
        {
            if ($element -match "\.") 
            {
                $ipaddress = $element            
            }
            elseif ($element -match "^\d+$")
            {
                $port = $element 
            }
            else
            {
                $serverName = $element
            }
        }
    }
    $machineName  = $serverName
    $instanceName = "MSSQLSERVER"
    if ($machineName -match "\\"){
        $serverSplitTemp = $machineName.Split("\")
        $machineName  = $serverSplitTemp[0]
        $instanceName = $serverSplitTemp[1]
    }
    if ($ipaddress -ne "") {
        $connection = $ipaddress
    } else {
        $connection = $machineName
    }
    if ($instanceName -ne "MSSQLSERVER") {
        $connection += "\" + $instanceName
    }
    if ($port -ne "") {
        $connection += "," + $port
    }
    Write-Output "Processing server $serverName"
    $startTime = get-date
    Write-Output "........Start $startTime" 

    $machineFolder = $dataFolder + $machineName
$machinefolder
    $instancefolder = $machinefolder + "\" + $instanceName
$instancefolder
    Write-Output "........Socket Information From SQL Server"
    $SocketINfo =   $dataFolder  +  "\" +$machineName + "_" + $instancename +"_socketinfo.csv"
$socketinfo
$machinename
#add-pssnapin sqlserverprovidersnapin100
#add-pssnapin sqlservercmdletsnapin100
    Invoke-Sqlcmd "SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],cpu_count/hyperthread_ratio AS [Physical CPU Count], physical_memory_in_bytes/1048576 AS [Physical Memory (MB)],@@servername as sqlservername,convert(sysname,serverproperty('machinename')) as Machinename FROM sys.dm_os_sys_info  WITH (NOLOCK) OPTION (RECOMPILE);" -serverinstance $servername | export-csv  $SocketINfo  

    
    $endTime = get-date
    Write-Output "........Stop $endTime" 
    $totalTime = $endTime - $startTime 
    Write-Output "........Time taken $totalTime" 
}
