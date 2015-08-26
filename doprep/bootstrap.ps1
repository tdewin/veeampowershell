Get-Volume | ? { (($_.DriveType -eq "CD-ROM") -and ($_.FileSystem -eq "UDF")) } | % {
    $doprep = ( "{0}:\doprep.ps1" -f $_.driveLetter)
    & $doprep
}
$myself = (Get-Variable MyInvocation).value.InvocationName
mv $myself ("{0}.bak" -f $myself) 