$Host.PrivateData.ConsolePaneBackgroundColor = "Black"
$host.UI.RawUI.BackgroundColor = "Black"

$logs=$(Get-ChildItem -Path "c:\programdata\Veeam\Backup" -Recurse -Filter *.log | ? { $_.Name -match "Job.Surebackup" } | % { $_.FullName });

$i=0;$logs | % { write-host ("{0} {1}" -f $i++,$_)};

function taillog { 
    param($n); get-content -Tail 1000 -wait $logs[$n] | % {
        if ($_ -match "[[]StableIp[]]") {
            write-host -BackgroundColor Black -ForegroundColor Yellow "$_"
        } elseif ($_ -match "[[]PrepareDC[]]") {
            write-host -BackgroundColor Black -ForegroundColor Yellow "$_"
        } else {
            write-host -BackgroundColor Black -ForegroundColor White "$_" 
        }
    } 
}