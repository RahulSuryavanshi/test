if(test-path -path 'E:\test.csv')
{
Remove-Item -path 'E:\test.csv'
}
$arrCounter =@('\\seslaptop-22\Process(*)\% Processor Time','\\seslaptop-22\Memory\Available MBytes','\\SESLAPTOP-22\LogicalDisk(_Total)\% Disk Read Time','\\SESLAPTOP-22\LogicalDisk(_Total)\% Disk Time','\\SESLAPTOP-22\LogicalDisk(_Total)\% Disk Write Time','\\SESLAPTOP-22\LogicalDisk(_Total)\% Free Space')
Get-Counter -Counter $arrCounter -SampleInterval 5 -MaxSamples 5   | ForEach {
        $_.CounterSamples | ForEach {
        if( $_.Path -like'*Process*' )
        {
            if( $_.Path -like'*postgre*' )
                {
                    [pscustomobject]@{
                        TimeStamp = $_.TimeStamp
                        Path = $_.Path
                        Value = $_.CookedValue
                        InstanceName=$_.InstanceName
        
                        }
                }
        }
        else
        {
            [pscustomobject]@{
                TimeStamp = $_.TimeStamp
                Path = $_.Path
                Value = $_.CookedValue
                InstanceName=$_.InstanceName
        
             }
        }
    
    }
    
} | Export-Csv -Path 'E:\test.csv'  -NoTypeInformation 
if(-not ( test-path -path 'E:\test.csv'))
{
Remove-Item -path 'E:\test.csv'
}