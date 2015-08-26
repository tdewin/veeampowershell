$myself = (Get-Variable MyInvocation).value.InvocationName
Get-Volume | ? { (($_.DriveType -eq "CD-ROM") -and ($_.FileSystem -eq "UDF")) } | % {
    $doprep = ( "{0}:\doprep.ps1" -f $_.driveLetter)
    if(Test-Path $doprep) {
        mv $myself ("{0}.bak" -f $myself) 
        & $doprep
    }
}

