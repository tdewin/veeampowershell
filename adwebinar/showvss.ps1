$break = 1
while($true) { 
    $serv = @(get-service | ? { $_.Name -imatch "Veeam" } | select Name,DisplayName,Starttype)

    start-sleep -Milliseconds 500
    if ($serv.Count -eq 0) {
        if ($break%30 -eq 0) {
            write-host .
        } else {
            Write-Host -NoNewline .
        }
    } else {
		$serv
	}
    $break++
}
