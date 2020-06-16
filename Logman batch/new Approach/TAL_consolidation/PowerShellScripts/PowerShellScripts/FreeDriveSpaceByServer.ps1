# Free Size per Server on the C drive (takes the same servers.txt that the other consolidation scripts read).


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

$Drives = @()

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
    $startTime = get-date



    $wmiLogicalDiskInfoFile = $instancefolder + "\WMILOGICALDISK_INFO.CSV"        
    gwmi -query "select * from Win32_LogicalDisk where DriveType=3" -computername $machineName |  ForEach-Object {
        $Name = $_.Name
        $FreeSpace = $_.FreeSpace
        
        $FreeSpace = $FreeSpace/1024 #kb
        $FreeSpace = $FreeSpace/1024 #mb
         
        
        if ($Name -eq 'C:') {
            $Drives = $Drives + "$serverName=$FreeSpace"
        }
    }
    

    $endTime = get-date
    $totalTime = $endTime - $startTime 
}

"Total MB free on the local C drive by Server:"
$Drives
