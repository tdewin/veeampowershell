param(
	$server = "localhost"
)

$failure = 1
try {
    $sess = new-pssession -cn $server -Authentication Negotiate
    $hostname = Invoke-Command -Session $sess -ScriptBlock {[system.environment]::MachineName }
    Write-Host ("Got result computername {0}" -f $hostname)
    #if we got so far that would be nice
    Remove-PSSession $sess
    $failure = 0
} catch {
    write-host ("Failure {0} " -f $error[0])
}
exit $failure