#run as admin
asnp veeampssnapin

$backups  = get-vbrbackup

$storagefiles = @()

#storages
$backups | % {
    $backup = $_
    $files = $backup.GetAllStorages()
    $files | % {
        $file = $_
        $storagefiles += New-Object -TypeName psobject -Property @{backupjob=$backup.Name;
            file=$file.FilePath;
            source=$file.Stats.DataSize;
            compress=$file.Stats.CompressRatio;
            dedup=$file.Stats.DedupRatio;
            backup=$file.Stats.BackupSize;
            
            }
    }
}
$storagefiles | ft

$restorepointsinfiles = @()

#restorepoints
$backups | % {
    $backup = $_
    $rps = $backup | Get-VBRRestorePoint

    $rps | % {
        $rp = $_
        #$rp.GetStorage()
        $disks = $rp.AuxData.Disks
        $disks | % {
            $disk = $_
            $restorepointsinfiles  += New-Object -TypeName psobject -Property @{backupjob=$backup.Name;
                vmname= $rp.VmName;
                creationtime=$rp.CreationTime;
                diskname=$disk.FileName;
                diskcapacity=$disk.Capacity;
             }
        }

    }
}
$restorepointsinfiles | ft