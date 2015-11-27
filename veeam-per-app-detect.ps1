$outfile = "c:\veeam-app-detection.html"

asnp veeampssnapin
$rps = Get-VBRRestorePoint

$ids = $rps | % { $_.ObjectId } | Sort-Object | Get-Unique
$apps = "HasAd","HasExchange","HasOracle","HasSQL","HasSharepoint"
$applist = @{}
$apps | % {
    $applist[$_] = @()
}

$ids | % {
    $id = $_
    $rpwithid = $rps | ? { $_.ObjectId -eq $id } | Sort-Object -Property creationtime -Descending
       
    $apps | % {
        $hasapp = $false
        $app = $_
        $detectedobject = 0
        for($i=0; ($i -lt $rpwithid.Count) -and (-not $hasapp); $i++) {
            $rpv = $rpwithid[$i]
            if($rpv."$app")
            {
                $hasapp = $true
                $detectedobject = New-Object -TypeName psobject -Property @{
                    Application=($app -replace "^Has","");
                    "VM Name"=$rpv.VmName;
                    FQDN=$rpv.Fqdn;
                    "Detection Date"=(get-date -format "yyyy/MM/dd" $rpv.CreationTime);
                    "Location"=$rpv.AuxData.Location
                }
            }
        }
        if($hasapp) {
            $applist[$app] += $detectedobject
        }
    }
}

$header = "<title>Veeam App Detection</title><style>body { font-family:arial } h1 { color:white;background-color:green; } table {border-collapse: collapse; } td,table,th { border: 1px solid black;padding:2px; } th { text-align:left; } .thVMName { width:100px; } .thFQDN { width:200px; } </style>"
$html = ""
$applist.Keys | Sort-Object | % {
    $apptab = $applist[$_]
    if($apptab.Count -gt 0) {
        $html += ("<h1>{0}</h1>" -f ($_ -replace "^Has",""))
        $html += ( $apptab | ConvertTo-Html -Property "Detection Date","Location","VM Name","FQDN" -Fragment) -replace "<th>([^<]*)</th>",'<th class=''th$1''>$1</th>'
        $html += "<br><br>"
    } 
}  
ConvertTo-Html -head $header -Body $html > $outfile
 