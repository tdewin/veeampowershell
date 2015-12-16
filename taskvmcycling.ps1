$NumberofVMs = 2
$AppGroupName = "Dynamic App Group"
$SbJobName = "Dynamic Surebackup Job"
$SbJobDesc = "Dynamic App Testing"

#cacheFile is just a txt file with every VM representing a VM that has been tested in previous runs
$cacheFile = "c:\d\surecache.txt"
if (-not (test-path $cacheFile)) { New-Item -ItemType file $cacheFile}

asnp "VeeamPSSnapIn" -ErrorAction SilentlyContinue

$date = (get-date)

# Find all VM objest successfully backed up in last 1 days
$VbrObjs = (Get-VBRBackupSession | ?{$_.JobType -eq "Backup" -and $_.EndTime -ge (get-Date).adddays(-1)}).GetTaskSessions() | ?{$_.Status -eq "Success" -or $_.Status -eq "Warning" }

if($VbrObjs.Count -lt $NumberofVMs) { $NumberofVMs = $VbrObjs.Count }

# Converting the array to arraylist. You can not use Remove in powershell on array, argh MS why do you expose this function if it doesnt work?! :(
[System.Collections.ArrayList]$VbrObjsArrayList = $VbrObjs
# Go over the file (% { } == foreach-object). If the line is not empty, and it is contained, remove it from the potential list
Get-Content $cacheFile | % { 
    $vmname = $_
    if ($vmname -ne "") {
        $toremove = $VbrObjsArrayList | ? { $_.name -eq $vmname }
        $toremove | % { $VbrObjsArrayList.Remove($_) }
    }
}

# Select random VMs to be tested
$TestVMs = @()
$reset = $false
# If the potential list is bigger than the number of VMs, select just random of VMs from the list
# Else almost all VMs have already been tested. Select all remaing VMs and reset the file
if($VbrObjsArrayList.Count -gt $NumberofVMs) {
    $TestVMs = $VbrObjsArrayList | get-random -Count $NumberofVMs
} else {
    $TestVMs = $VbrObjsArrayList
    $reset = $true
}

$VirtualLab = Get-VSBVirtualLab -Name "Surebackup Lab"
$AppGroup = Add-VSBViApplicationGroup -Name $AppGroupName -VmFromBackup (Find-VBRViEntity -Name $TestVMs.Name)
$VsbJob = Add-VSBJob -Name $SbJobName -VirtualLab $VirtualLab -AppGroup $AppGroup -Description $SbJobDesc

if($reset) {
   "" > $cacheFile
} else {
    $TestVMs | % { Add-Content $cacheFile ("`n{0}" -f $_.name )}
}