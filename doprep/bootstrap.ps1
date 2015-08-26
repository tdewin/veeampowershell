Get-Volume | ? { (($_.DriveType -eq "CD-ROM") -and ($_.FileSystem -eq "UDF")) } | % {
    $doprep = ( "{0}:\doprep.ps1" -f $_.driveLetter)
    & $doprep
}