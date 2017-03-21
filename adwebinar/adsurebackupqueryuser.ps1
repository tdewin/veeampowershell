#use single quote for sbase so powershell does not tries to make an array out of it
param( 
    $server="127.0.0.1",
    $minusers=1000,
    $sbase='OU=Chicago,OU=Global,DC=team,DC=local'
)
$failure = 1
try {
    $q = @(Get-ADUser -Server $server -SearchBase $sbase -Filter * -ErrorAction SilentlyContinue)
    if ($q.Count -gt $minusers) {
        $failure = 0
        write-host ("Got {0} users in {1}" -f $q.Count,$sbase)
    } else {
        write-host ("Succesful query but not enough users {0} vs {1}" -f $q.Count, $minusers )
    }
} catch {
    write-host ("Error occured {0}" -f $Error[0].ToString())
}
exit $failure