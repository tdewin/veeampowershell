#$lookfor = "network";gwmi -List | ? { $_.name -match $lookfor } | select name,properties | fl

$old = gwmi Win32_PerfRawData_PerfDisk_PhysicalDisk  -Filter "Name LIKE '_TOTAL'" -Property "DiskBytesPersec","Timestamp_Sys100NS"
$oldnet = gwmi Win32_PerfRawData_Tcpip_NetworkInterface -Filter "NOT Name LIKE '%isatap%'" -Property "Name","BytesTotalPersec","Timestamp_Sys100NS"


while ( 1 -eq 1 ) {
    sleep -Milliseconds 900
    $new = gwmi Win32_PerfRawData_PerfDisk_PhysicalDisk -Filter "Name LIKE '_TOTAL'" -Property "DiskBytesPersec","Timestamp_Sys100NS"
    $newnet = gwmi Win32_PerfRawData_Tcpip_NetworkInterface -Filter "NOT Name LIKE '%isatap%'" -Property "Name","BytesTotalPersec","Timestamp_Sys100NS"
    
    #disk
    $dbs = $new.DiskBytesPersec - $old.DiskBytesPersec
    $time = ($new.Timestamp_Sys100NS-$old.Timestamp_Sys100NS)*1e-7
    #or
    #really formula
    #lookup counter and type https://msdn.microsoft.com/en-us/library/aa394308%28v=vs.85%29.aspx
    #match id to type https://msdn.microsoft.com/en-us/library/aa389383%28v=vs.85%29.aspx
    #based on counter type : https://technet.microsoft.com/en-us/library/cc757486%28v=ws.10%29.aspx
    #$time = ($new.Timestamp_PerfTime - $old.Timestamp_PerfTime)/($new.Frequency_PerfTime)
    
    $kdbs = $dbs/1024 
    write-host ("Disk : {0}`t`t{1}" -f ($kdbs/$time),$time)

    #network
    $totalbytes = 0
    $nettime = 0
    $newnet | % {
        $newif = $_
        $oldif = @($oldnet | ? { $_.name -eq $newif.name })
        if ($oldif.Count -gt 0) {
            $oldif = $oldif[0]
            #Write-Host ("{0} {1}" -f $newif.name,$oldif.name )
            $nettime = ($newif.Timestamp_Sys100NS-$oldif.Timestamp_Sys100NS)*1e-7
            #or
            #really formula
            #lookup counter and type https://msdn.microsoft.com/en-us/library/aa394308%28v=vs.85%29.aspx
            #match id to type https://msdn.microsoft.com/en-us/library/aa389383%28v=vs.85%29.aspx
            #based on counter type : https://technet.microsoft.com/en-us/library/cc757486%28v=ws.10%29.aspx
            #$nettime = ($newif.Timestamp_PerfTime - $oldif.Timestamp_PerfTime)/($newif.Frequency_PerfTime)


            $totalbytes += ($newif.BytesTotalPersec - $oldif.BytesTotalPersec)/$nettime

        }
    }
    write-host ("Net Kbit/s : {0}`t`t{1}" -f ($totalbytes*8/1024),$nettime)

    $old = $new
    $oldnet = $newnet
}