#To generate password, run powershell as service account and then run the following command to make an encrypted password. It can only be decrypted as service user!
#PS c:\somepath>Read-Host -AsSecureString | ConvertFrom-SecureString | clip
#you can also use the very unsecure way but this is not recommeded
#("myplainpass" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString)
param(
    $server = "127.0.0.1",
    $path = "/Shared%20Documents/contenttest.txt",
    $content = "sharepoint is working succesfully",
    [bool]$https = $false,
    $username = "domain\testaccount",
    $pass = ("myplainpass" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString)
)
Write-host ("Running as {0}" -f (whoami))

if($path.Length -eq 0 -or $path[0] -ne "/") {
 $path = ("/{0}" -f $path)
}
$sec = ""
if($https) { $sec = "s" }


$dlstring = ("http{2}://{0}{1}" -f $server,$path,$sec)

$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,($pass | convertto-securestring)
$web = New-Object Net.WebClient
$failure = 1
try {
    $web.Credentials = $cred
    $contentread = $web.DownloadString($dlstring)
    if($contentread -eq $content ) {
        write-host ("Got match ""{0}"" in {1}" -f $content,$dlstring)
        $failure = 0
    }
    else {
        write-host ("No match ""{0}"" on {1} != ""{2}""" -f $contentread,$dlstring,$content)
        $failure = 1
    }
} catch {
    write-host $Error[0].Exception.Message
    $failure = 1
}
exit $failure