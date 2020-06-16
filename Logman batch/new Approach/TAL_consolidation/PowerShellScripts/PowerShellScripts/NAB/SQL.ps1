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
$mainFolder  = "C:\TAL_consolidation\PowerShellScripts"

#
# D O    N O T    M O D I F Y    B E L O W    T H I S    L I N E
#

$scriptsFolder  = $mainFolder + "\PowershellScripts\"
$serversFile = $scriptsFolder + "servers.txt"
$serversNotResponding = $scriptsFolder + "serversnotresponding.txt"

$dataFolder  = $mainFolder + "\Data\"

$serverNameLine     = Get-Content -Path $serversFile

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
    $instancefolder = $machinefolder + "\" + $instanceName

    Write-Output "........Win32_ComputerSystem"
    $wmiComputerSystemInfoFile = $instancefolder + "\WMICOMPUTERSYSTEM_INFO.CSV"        
    gwmi -query "select * from Win32_ComputerSystem" -computername $machineName | select Name,
        		 Model, Manufacturer, Description, PCSystemType, DNSHostName,
        		 Domain, DomainRole, PartOfDomain, NumberOfLogicalProcessors, NumberOfProcessors,
        		 SystemType, TotalPhysicalMemory, UserName, Workgroup, CurrentTimeZone,
                 PrimaryOwnerContact, PrimaryOwnerName,Status  | export-csv -path $wmiComputerSystemInfoFile -noType

    Write-Output "........Win32_Processor"
    $wmiProcessorInfoFile = $instancefolder + "\WMIPROCESSOR_INFO.CSV"        
    gwmi -query "select * from Win32_Processor" -computername $machineName | select Name,DeviceID,AddressWidth,Architecture,Caption,CpuStatus,
            CurrentClockSpeed,DataWidth,Description,ExtClock,Family,
            L2CacheSize,L2CacheSpeed,L3CacheSize,L3CacheSpeed,Manufacturer,
            MaxClockSpeed,NumberOfCores,NumberOfLogicalProcessors,
            ProcessorId,ProcessorType,Revision,
            SocketDesignation,Status,Stepping  | export-csv -path $wmiProcessorInfoFile -noType

    Write-Output "........Win32_OperatingSystem"
    $wmiOperatingSystemInfoFile = $instancefolder + "\WMIOPERATINGSYSTEM_INFO.CSV"        
    gwmi -query "select * from Win32_OperatingSystem" -computername $machineName | select Name,
        		 Version, FreePhysicalMemory, OSLanguage, OSProductSuite,
        		 OSType, ServicePackMajorVersion, ServicePackMinorVersion | export-csv -path $wmiOperatingSystemInfoFile -noType

    Write-Output "........Win32_PhysicalMemory"
    $wmiPhysicalMemoryInfoFile = $instancefolder + "\WMIPHYSICALMEMORY_INFO.CSV"        
    gwmi -query "select * from Win32_PhysicalMemory" -computername $machineName | select Name, Capacity, DeviceLocator,
        		 Tag | export-csv -path $wmiPhysicalMemoryInfoFile -noType

    Write-Output "........Win32_LogicalDisk"
    $wmiLogicalDiskInfoFile = $instancefolder + "\WMILOGICALDISK_INFO.CSV"        
    gwmi -query "select * from Win32_LogicalDisk where DriveType=3" -computername $machineName | select Name, FreeSpace,
        		 Size | export-csv -path $wmiLogicalDiskInfoFile -noType

    Write-Output "........connecting to the server $connection"
    $serverObject = New-Object Microsoft.SqlServer.Management.Smo.Server($connection)
    $buildNumber = $serverObject.BuildNumber

    if ($buildNumber -gt 0){
        Write-Output "........ServerInfo"
        $serverInfoFile = $instancefolder + "\SERVER_INFO.CSV"
        $serverObject | export-csv -path $serverInfoFile -noType
                
        Write-Output "........sp_configure"
        $spConfigureFile = $instancefolder + "\SP_CONFIGURE.CSV"        
        $serverObject.Configuration.Properties | export-csv -path $spConfigureFile -noType
                
        Write-Output "........databases"
        $databaseInfoFile = $instancefolder + "\DATABASE_INFO.CSV"        
        $serverObject.Databases | export-csv -Path $databaseInfoFile -notype
        $filegroupsInfoFile = $instancefolder + "\FILEGROUPS_INFO.CSV"        
        $logfileInfoFile = $instancefolder + "\LOGFILES_INFO.CSV"        
        $fulltextInfoFile = $instancefolder + "\FULLTEXT_INFO.CSV"        
        $datafileInfoFile = $instancefolder + "\DATAFILES_INFO.CSV"        
        $stringToWrite = '"Database","FilegroupName","Parent","AvailableSpace","BytesReadFromDisk","BytesWrittenToDisk","FileName","Growth","GrowthType","ID","IsOffline","IsPrimaryFile","IsReadOnly","IsReadOnlyMedia","IsSparse","MaxSize","NumberOfDiskReads","NumberOfDiskWrites","Size","UsedSpace","VolumeFreeSpace","Name","Urn","UserData","State"'
        Add-Content -Path $datafileInfoFile -Value $stringToWrite
        $dbcount = 0
        Foreach ($database in $serverObject.Databases){ 
            if ($dbcount -eq 0) {
                $filegroups = $database.FileGroups
                $logfiles = $database.LogFiles
                $fulltexts = $database.FullTextCatalogs
                $dbcount += 1
            }else {
                $filegroups += $database.FileGroups
                $logfiles += $database.LogFiles
                $fulltexts += $database.FullTextCatalogs
            }            
            $dbname = $database.Name
            Foreach($filegroup in $database.FileGroups){
                $fgname = $filegroup.Name
                Foreach($file in $filegroup.Files) {
                    $parent = $file.Parent
                    $availablespace = $file.AvailableSpace
                    $bytesreadfromdisk = $file.BytesReadFromDisk
                    $byteswrittentodisk = $file.BytesWrittenToDisk
                    $filename = $file.FileName
                    $growth = $file.Growth
                    $growthtype = $file.GrowthType
                    $id = $file.ID
                    $isoffline = $file.IsOffline
                    $isprimaryfile = $file.IsPrimaryFile
                    $isreadonly = $file.IsReadOnly
                    $isreadonlymedia = $file.IsReadOnlyMedia
                    $issparse = $file.IsSparse
                    $maxsize = $file.MaxSize
                    $numberofreads = $file.NumberOfDiskReads
                    $numberofdiskwrites = $file.NumberOfDiskWrites
                    $size = $file.Size
                    $usedspace = $file.UsedSpace
                    $volumefreespace = $file.VolumeFreeSpace
                    $name = $file.Name
                    $urn = $file.Urn
                    $userdata = $file.UserData
                    $state = $file.State
                    $stringToWrite = """$dbname"",""$fgname"",""$Parent"",$AvailableSpace,$BytesReadFromDisk,$BytesWrittenToDisk,""$FileName"",$Growth,""$GrowthType"",$ID,""$IsOffline"",""$IsPrimaryFile"",""$IsReadOnly"",""$IsReadOnlyMedia"",""$IsSparse"",""$MaxSize"",$NumberOfDiskReads,$NumberOfDiskWrites,$Size,$UsedSpace,$VolumeFreeSpace,""$Name"",""$Urn"",""$UserData"",""$State"""
                    Add-Content -Path $datafileInfoFile -Value $stringToWrite     
                }    
            }                
        }                        
        $filegroups | export-csv -path $filegroupsInfoFile -notype
        $logfiles | export-csv -path $logfileInfoFile -notype
        $fulltexts | export-csv -path $fulltextInfoFile -notype

        Write-Output "........linkedservers"
        $linkedserversInfoFile = $instancefolder + "\LINKEDSERVERS_INFO.CSV"        
        $serverObject.LinkedServers | export-csv -Path $linkedserversInfoFile -notype

        Write-Output "........errorlogs"
        $errorLogs = $serverObject.EnumErrorLogs()    
        $errorLogCount = 0
        foreach ($row in $errorLogs.Rows)
        {
            if ($errorLogCount -gt 2) {
                break
            }
            $errorLogID = $row[2]
            if ($errorLogID -eq 0){
                $errorLogExportFile = $instancefolder + "\ERRORLOG.txt"
                $serverObject.ReadErrorLog() | export-csv -path $errorLogExportFile -noType
            } else {
                $errorLogExportFile = $instancefolder + "\ERRORLOG_" + $errorLogID + ".txt"
                $serverObject.ReadErrorLog($errorLogID) | export-csv -path $errorLogExportFile -noType
            }
            $errorLogCount++
        }
    }else{
        Write-Output "........SERVER NOT RESPONDING"
        Add-Content -Path $serversNotResponding -Value $serverName
    }
    $endTime = get-date
    Write-Output "........Stop $endTime" 
    $totalTime = $endTime - $startTime 
    Write-Output "........Time taken $totalTime" 
}
