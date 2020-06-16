# prepConsolidation.ps1
# Prepares the scripts and the folder structure for consolidation
#
# Change log:
# May 23, 2011: Bhushan Punjabi
#   Counters count reduced, as per Larry
# April 15, 2011: Yogesh Bhalerao
#   Updated to also add IP address in the servers.txt
# January 10, 2011: Yogesh Bhalerao
#   Initial Version

# Replace "C:\Users\ybhalerao\Documents\Project\Others\Test" with the actual root folder on the central server
# Note: Do not add the "\" at the end of the root folder
$mainFolder  = "C:\TAL_consolidation\PowerShellScripts"

# Set the perfmon parameters
# Replace "C:\Temp" and "C$\Temp" with the actual folder on the SQL Server where you want to store the perfmon file
$isCollectionOnCentralServer = 0
$perfMonLocalOutputFolderName = "C:\"
$perfMonNetworkOutputFolderName = "C$\"
$perfmonStartTime = "11/06/2019 10:00:00AM"
$perfmonEndTime = "11/06/2019 10:15:00AM"
$perfmonSamplingInterval = "00:05:00"
$perfmonMaxSize = "100"

#
# D O    N O T    M O D I F Y    B E L O W    T H I S    L I N E
#

$scriptsFolder  = $mainFolder + "\PowershellScripts\"
$serversFile = $scriptsFolder + "servers.txt"
$sqlInputFile = $scriptsFolder + "sql_script.sql"

$dataFolder  = $mainFolder + "\Data\"

$perfMonTemplateFolderName = "\PerfMonTemplates"
$perfMonTemplateFolder = $mainFolder + $perfMonTemplateFolderName
$perfmonCounterLogNamePrefix = "se_consolidation_"
$createPerfFile = $perfMonTemplateFolder + "\create_perf.bat"
$startPerfFile = $perfMonTemplateFolder + "\start_perf.bat"
$stopPerfFile = $perfMonTemplateFolder + "\stop_perf.bat"
$deletePerfFile = $perfMonTemplateFolder + "\delete_perf.bat"
$movePerfFile = $perfMonTemplateFolder + "\move_perf.bat"
$deletePerfFolder = $perfMonTemplateFolder + "\delete_perf_folder.bat"
$dirPerfFolder = $perfMonTemplateFolder + "\dir_perf_folder.bat"
$sqlScriptFolderName = "\SQLScript"
$sqlScriptFolder = $mainFolder + $sqlScriptFolderName
$sqlOutputFileName = "SQL_OUTPUT.txt"
$runSQLBatchFile = $sqlScriptFolder + "\run_sql.bat"

[String[]]$sServerArray = ""
[String[]]$sInstanceArray = ""
[String[]]$sIPAddressArray = ""

$serverNameLine     = Get-Content -Path $serversFile

function doesServerNameExistsInArray($serverName) {
    $elementExists = -1;
    $count = 0
    foreach ($sServer in $sServerArray){
        if ($sServer -eq $serverName){
            $elementExists = $count;
            break;
        }                
        $count += 1
    }
    return $elementExists
}

function doesInstanceNameExistsInArray($serverIndex, $instanceName) {
    $elementExists = -1;
    $sInstances = $sServerArray[$serverIndex]
    foreach ($sInstance in $sInstances){
        if ($instanceName -match $sInstance){
            $elementExists = 1;
            break;
        }                
    }
    return $elementExists
}

function generatePerfMonContent {
    param(
    [String]$ipAddress,
    [String]$machineName,
    [String]$instanceString
    )
    $perfmonFile = $perfMonTemplateFolder + "\" + $machineName + ".template"
    if ($instanceString -notmatch "\\") {
        [String[]]$sInstances = ""
        $sInstances[0] = $instanceString
    } else {
        $sInstances = $instanceString.Split("\")    
    }
    $appendMachineName = ""
    if ($isCollectionOnCentralServer -eq 1)
    {
        $appendMachineName = "\\" + $machineName
    }    
	
	#Logical Disk Counters
	$stringToWrite = $appendMachineName + "\LogicalDisk(*)\Avg. Disk sec/Read"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\LogicalDisk(*)\Avg. Disk sec/Transfer"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\LogicalDisk(*)\Avg. Disk sec/Write"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\LogicalDisk(*)\Disk Bytes/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\LogicalDisk(*)\Disk Read Bytes/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\LogicalDisk(*)\Disk Write Bytes/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\LogicalDisk(*)\Disk Reads/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\LogicalDisk(*)\Disk Transfers/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\LogicalDisk(*)\Disk Writes/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	
    #Memory Counters	
    $stringToWrite = $appendMachineName + "\Memory\Pages/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\Memory\Available MBytes"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	
    #System Counters
    $stringToWrite = $appendMachineName + "\System\Context Switches/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\System\Processor Queue Length"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	
    #Network Interface Counters	
    $stringToWrite = $appendMachineName + "\Network Interface(*)\Bytes Total/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\Network Interface(*)\Output Queue Length"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\Network Interface(*)\Packets/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	
	#Process Counters
	for ($i = 0; $i -le ($sInstances.length - 1); $i += 1) {
        if ($i -eq 0) {
            $stringToWrite = $appendMachineName + "\Process(sqlservr)\*"
        } else {
            $stringToWrite = $appendMachineName + "\Process(sqlservr#" + $i + ")\*"
        }
        Add-Content -Path $perfmonFile -Value $stringToWrite
    }
    $stringToWrite = $appendMachineName + "\Process(_Total)\Processor Time"
    Add-Content -Path $perfmonFile -Value $stringToWrite	
	$stringToWrite = $appendMachineName + "\Process(_Total)\User Time"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	$stringToWrite = $appendMachineName + "\Process(_Total)\IO Data Operations/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	$stringToWrite = $appendMachineName + "\Process(_Total)\Page Faults/sec"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	$stringToWrite = $appendMachineName + "\Process(_Total)\Private Bytes"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	$stringToWrite = $appendMachineName + "\Process(_Total)\Thread Count"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	$stringToWrite = $appendMachineName + "\Process(_Total)\Virtual Bytes"
    Add-Content -Path $perfmonFile -Value $stringToWrite
	$stringToWrite = $appendMachineName + "\Process(_Total)\Working Set"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    
    #Processor Counters
	$stringToWrite = $appendMachineName + "\Processor(_Total)\% Processor Time"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    $stringToWrite = $appendMachineName + "\Processor(_Total)\% User Time"
    Add-Content -Path $perfmonFile -Value $stringToWrite
    
	#SQL Counters
	for ($i = 0; $i -le ($sInstances.length - 1); $i += 1) {
        if ($sInstances[$i] -eq "MSSQLSERVER"){
            $instanceName = "\SQLServer"
        }else {
            $instanceName = "\MSSQL$" + $sInstances[$i]
        }
        $stringToWrite = $appendMachineName + $instanceName + ":Buffer Manager\Buffer cache hit ratio"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Buffer Manager\Free list stalls/sec"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Buffer Manager\Lazy writes/sec"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Buffer Manager\Page life expectancy"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Databases(*)\Data File(s) Size (KB)"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Databases(*)\Log File(s) Size (KB)"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Databases(*)\Transactions/sec"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":General Statistics\Logins/sec"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":General Statistics\User Connections"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Memory Manager\Granted Workspace Memory (KB)"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Memory Manager\Memory Grants Pending"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Memory Manager\SQL Cache Memory (KB)"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Memory Manager\Target Server Memory (KB)"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":Memory Manager\Total Server Memory (KB)"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":SQL Statistics\Batch Requests/sec"
        Add-Content -Path $perfmonFile -Value $stringToWrite
        $stringToWrite = $appendMachineName + $instanceName + ":SQL Statistics\SQL Compilations/sec"
        Add-Content -Path $perfmonFile -Value $stringToWrite
    }

    $machineFolder = $dataFolder + $machineName    
    $perfmonCounterLogNamePrefixWithMachineName = $perfmonCounterLogNamePrefix + $machineName
    $strExecution = " -s " + $machineName
    $serverMachineName = $machineName
    if ($ipAddress -ne "") {
    	$strExecution = " -s " + $ipAddress
        $serverMachineName = $ipAddress
    } 
    if ($isCollectionOnCentralServer -eq 1)
    {
        $strExecution = ""
    }    
    Add-Content -Path $createPerfFile -Value "Echo Create: $machineName >> `"$perfMonTemplateFolder\CREATE_OUTPUT.txt`""
    $stringToWrite = "logman create counter " + $perfmonCounterLogNamePrefixWithMachineName + $strExecution + " -cf `"" + $perfmonFile + "`" -si " + $perfmonSamplingInterval + " -b " + $perfmonStartTime + " -e " + $perfmonEndTime + " -max " + $perfmonMaxSize + " -f bin -o `"" + $perfMonLocalOutputFolderName + "\" + $machineName + "`" >> `"" + $perfMonTemplateFolder + "\CREATE_OUTPUT.txt`""
    Add-Content -Path $createPerfFile -Value $stringToWrite
    Add-Content -Path $startPerfFile -Value "Echo Start: $machineName >> `"$perfMonTemplateFolder\START_OUTPUT.txt`""
    $stringToWrite = "logman start " + $perfmonCounterLogNamePrefixWithMachineName + $strExecution +  " >> `"" + $perfMonTemplateFolder + "\START_OUTPUT.txt`""
    Add-Content -Path $startPerfFile -Value $stringToWrite
    Add-Content -Path $stopPerfFile -Value "Echo Stop: $machineName >> `"$perfMonTemplateFolder\STOP_OUTPUT.txt`""
    $stringToWrite = "logman stop " + $perfmonCounterLogNamePrefixWithMachineName + $strExecution +  " >> `"" + $perfMonTemplateFolder + "\STOP_OUTPUT.txt`""
    Add-Content -Path $stopPerfFile -Value $stringToWrite
    Add-Content -Path $deletePerfFile -Value "Echo Delete: $machineName >> `"$perfMonTemplateFolder\DELETE_OUTPUT.txt`""
    $stringToWrite = "logman delete " + $perfmonCounterLogNamePrefixWithMachineName + $strExecution +  " >> `"" + $perfMonTemplateFolder + "\DELETE_OUTPUT.txt`""
    Add-Content -Path $deletePerfFile -Value $stringToWrite
    if ($isCollectionOnCentralServer -ne 1)
    {
        Add-Content -Path $movePerfFile -Value "Echo Move: $machineName >> `"$perfMonTemplateFolder\MOVE_OUTPUT.txt`""
        $stringToWrite = "move /Y `"\\" + $serverMachineName + "\" + $perfMonNetworkOutputFolderName + "\*.blg`" `"" + $machineFolder + "\PerfMon`"  >> `"" + $perfMonTemplateFolder + "\MOVE_OUTPUT.txt`""
        Add-Content -Path $movePerfFile -Value $stringToWrite    
        Add-Content -Path $deletePerfFolder -Value "Echo Delete: $machineName >> `"$perfMonTemplateFolder\DELETEFOLDER_OUTPUT.txt`""
        $stringToWrite = "rd `"\\" + $serverMachineName + "\" + $perfMonNetworkOutputFolderName + "`" >> `"" + $perfMonTemplateFolder + "\DELETEFOLDER_OUTPUT.txt`""
        Add-Content -Path $deletePerfFolder -Value $stringToWrite
        Add-Content -Path $dirPerfFolder -Value "Echo Dir: $machineName >> `"$perfMonTemplateFolder\DIR_OUTPUT.txt`""
        $stringToWrite = "dir `"\\" + $serverMachineName + "\" + $perfMonNetworkOutputFolderName + "\*.blg`" >> `"" + $perfMonTemplateFolder + "\DIR_OUTPUT.txt`""
        Add-Content -Path $dirPerfFolder -Value $stringToWrite
    }    
}

function createFolders {
    param(
    [String]$machineName,
    [String]$instanceString
    )
    Write-Host "------ Machine: $machineName"
    Write-Host "------ Instance: $instanceString"
    $machineFolder = $dataFolder + $machineName
    if (!(Test-Path -Path $machinefolder))
    {
        New-Item -Path $dataFolder -Name $machineName -Item directory    
        New-Item -Path $machineFolder -Name "PerfMon" -Item directory    
    }
    $instancefolder = $machinefolder + "\" + $instanceName
    if (!(Test-Path -Path $instancefolder))
    {
        New-Item -Path  $machinefolder -Name $instanceName -Item directory    
    }    
}

# Create the folders
if (!(Test-Path -Path $sqlScriptFolder)){
    New-Item -Path $mainFolder -Name $sqlScriptFolderName -Item directory    
}
if (!(Test-Path -Path $perfMonTemplateFolder)){
    New-Item -Path $mainFolder -Name $perfMonTemplateFolderName -Item directory    
}

foreach ($serverLine in $serverNameLine)
{
    if ($serverLine -ne "") {
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
        createFolders -machineName $machineName -instanceString $instanceName
    }        
}

# Create PerfMon Template File
foreach ($serverLine in $serverNameLine)
{
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
    if ($machineName -ne ""){
        $machineExists = doesServerNameExistsInArray $machineName
        if ($machineExists -lt 0) {
            if ($sServerArray[0] -eq "") {
                $sServerArray[0] = $machineName
                $sIPAddressArray[0] = $ipaddress
                $machineExists = 0
            } else {
                $sServerArray   += $machineName
                $sInstanceArray += ""
                $sIPAddressArray += $ipaddress
                $machineExists   = $sServerArray.Length - 1
            }
        }
        #Add the Instance Name        
        $instanceExists = doesInstanceNameExistsInArray $machineExists, $instanceName
        if ($instanceExists -lt 0){
            $instanceString = $sInstanceArray[$machineExists]
            if ($instanceString -eq ""){
                $instanceString = $instanceName
            }else {
                $instanceString += "\" + $instanceName
            } 
            $sInstanceArray[$machineExists] = $instanceString
        }        
    }
}

#Now create the template
for ($i = 0; $i -le ($sServerArray.length - 1); $i += 1) {
    $sServer    = $sServerArray[$i]
    $sInstances = $sInstanceArray[$i]
    $sIPAddress = $sIPAddressArray[$i]
    generatePerfMonContent -ipaddress $sIPAddress $sipaddress -machineName $sServer -instanceString $sInstances -fileName $perfmonFile
}

#Now create the output files
$output_file = $perfMonTemplateFolder + "\CREATE_OUTPUT.txt"
Add-Content -Path $output_file -Value "--"
$output_file = $perfMonTemplateFolder + "\START_OUTPUT.txt"
Add-Content -Path $output_file -Value "--"
$output_file = $perfMonTemplateFolder + "\STOP_OUTPUT.txt"
Add-Content -Path $output_file -Value "--"
$output_file = $perfMonTemplateFolder + "\DELETE_OUTPUT.txt"
Add-Content -Path $output_file -Value "--"
$output_file = $perfMonTemplateFolder + "\MOVE_OUTPUT.txt"
Add-Content -Path $output_file -Value "--"
$output_file = $perfMonTemplateFolder + "\DELETE_FOLDER_OUTPUT.txt"
Add-Content -Path $output_file -Value "--"
$output_file = $perfMonTemplateFolder + "\DIR_OUTPUT.txt"
Add-Content -Path $output_file -Value "--"

#Now create the SQL Script batch file
foreach ($serverLine in $serverNameLine)
{
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
    $machineFolder = $dataFolder + $machineName
    $instancefolder = $machinefolder + "\" + $instanceName
    
    $sqlOutputFile = $instancefolder + "\" + $sqlOutputFileName
    $command = 'sqlcmd -i "' + $sqlInputFile + '" -S ' + $connection + ' > "' + $sqlOutputFile + '"'    
    Add-Content -Path $runSQLBatchFile $command
}
