$backupdir = "c:\adconfig"
$backupfilefsmo = "$backupdir\fsmo.txt"

New-Item -Path $backupdir -ItemType Directory -ErrorAction SilentlyContinue
$roles = @()
$domain = Get-ADDomain
@("PDCEmulator","InfrastructureMaster","RIDMaster") | % {
    $roles += (“{1,-20} {0}” –f $_,$domain."$_")
}
$forest = Get-ADForest
@("DomainNamingMaster","SchemaMaster") | % {
    $roles += (“{1,-20} {0}” –f $_,$forest."$_")
}

$roles | Out-File -FilePath $backupfilefsmo -Force