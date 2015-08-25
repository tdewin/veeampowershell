<#
 #create password by
 $credential = get-credential
 $password = ConvertFrom-SecureString $credential.password
 write-host ("username=""{0}"";password=""{1}""" -f $credential.username,$password)
#>
$instances = @()
$instances += New-Object -TypeName psobject -Property @{customer="mycustomer";server="192.168.93.17";username="v\administrator";password="<<encrypted standard string>>"}
$instances += New-Object -TypeName psobject -Property @{customer="mycustomer";server="192.168.93.17";username="v\administrator";password="<<encrypted standard string>>"}


$globaljob = @()

$instances | % {
    $i = $_


    $errorvar = 0
    $session = New-PSSession -ComputerName $i.server -Credential (New-Object System.Management.Automation.PSCredential ($i.username, (ConvertTo-SecureString $i.password)))  -ErrorAction SilentlyContinue -ErrorVariable errorvar
    if($errorvar -eq 0)
    {
        $jobs = Invoke-Command -Session $session -ScriptBlock { 
            asnp veeampssnapin

            $wireresult = @()

            get-vbrjob | % {
                $job = $_
                $ls = $job.FindLastSession()
                $wireresult += New-Object -typename psobject -property @{name=$job.Name;result=$ls.Result;endtime=$ls.EndTime}
            }

            $wireresult
        } -ErrorAction SilentlyContinue -ErrorVariable errorvar
    }


    if($errorvar)
    {
        $globaljob += New-Object -TypeName psobject -Property @{customer=$i.customer;backupserver=$i.server;name="";result="";endtime="";fetcherror=$errorvar}
        write-host 
    }
    else {
        $jobs | % {
            $globaljob += New-Object -TypeName psobject -Property @{customer=$i.customer;backupserver=$i.server;name=$_.Name;result=$_.result;endtime=$_.endtime;fetcherror=0}
        }
    }
    $session | Remove-PSSession -ErrorAction SilentlyContinue
}
$globaljob | ft