param(
    $server="127.0.0.1"
)
$failure = 1
$web = New-Object Net.WebClient
try {
    $data = $web.DownloadString("http://$server/owncloud/index.php")
    if($data -match "/owncloud/core/img/actions/password.svg") {
        $failure = 0
    }
} catch {

}
exit $failure