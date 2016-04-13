#self signed error dismiss
#http://www.datacore.com/RESTSupport-Webhelp/using_windows_powershell_as_a_rest_client.htm
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


#get the api
$r_api = Invoke-WebRequest -Method Get -Uri "https://localhost:9398/api/" 
$r_api_xml = [xml]$r_api.Content
$r_api_links = @($r_api_xml.EnterpriseManager.SupportedVersions.SupportedVersion | ? { $_.Name -eq "v1_2" })[0].Links


#login
$r_login = Invoke-WebRequest -method Post -Uri $r_api_links.Link.Href -Credential (Get-Credential -Message "Basic Auth" -UserName "rest")
#even more raw
#$auth = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("mylogin:myadvancedpassword"))
#$r_login = Invoke-WebRequest -method Post -Uri $r_api_links.Link.Href -Headers @{"Authorization"=$auth}


if ($r_login.StatusCode -lt 400) {
    #get session id which we need to do subsequent request
    $sessionheadername = "X-RestSvcSessionId"
    $sessionid = $r_login.Headers[$sessionheadername]

    #content
    $r_login_xml = [xml]$r_login.Content
    $r_login_links = $r_login_xml.LogonSession.Links.Link
    $joblink = $r_login_links | ? { $_.Type -eq "JobReferenceList" }

    #get jobs with id we have
    $r_jobs = Invoke-WebRequest -Method Get -Headers @{$sessionheadername=$sessionid} -Uri $joblink.Href
    $r_jobs_xml = [xml]$r_jobs.Content
    $r_job = $r_jobs_xml.EntityReferences.Ref | ? { $_.Name -Match "timo_cbt" }
    $r_job_alt = $r_job.Links.Link | ? { $_.Rel -eq "Alternate" }

    #get detail about job "entity format"
    $r_job_entity = Invoke-WebRequest -Method Get -Headers @{$sessionheadername=$sessionid} -Uri $r_job_alt.Href
    $r_job_entity_xml = [xml]$r_job_entity.Content
    $r_job_start = $r_job_entity_xml.Job.Links.Link | ? { $_.Rel -eq "Start" }

    #start the job
    $r_start = Invoke-WebRequest -Method Post -Headers @{$sessionheadername=$sessionid} -Uri $r_job_start.Href
    $r_start_xml =  [xml]$r_start.Content 

    #check of command is succesfully delegated
    while ( $r_start_xml.Task.State -eq "Running") {
        $r_start = Invoke-WebRequest -Method Get -Headers @{$sessionheadername=$sessionid} -Uri $r_start_xml.Task.Href
        $r_start_xml =  [xml]$r_start.Content
        write-host $r_start_xml.Task.State
        Start-Sleep -Seconds 1
    }
    write-host $r_start_xml.Task.Result

    #find the query svc
    $qsvclink = $r_login_links | ? { $_.Type -eq "QueryService" }
    $r_query = Invoke-WebRequest -Method Get -Headers @{$sessionheadername=$sessionid} -Uri $qsvclink.Href
    $r_query_xml = [xml]$r_query.Content
  
    #build the query
    $qbackupsessionlink = $r_query_xml.QuerySvc.Links.Link | ? { $_.Type -Match "BackupJobSessionList"}
    $spliturl = $qbackupsessionlink.Href -split "[?]"
    $arg = ("type=BackupJobSession&format=Entities&sortDesc=Name&pageSize=1&page=1&filter=(JobName=={0})" -f $r_job_entity_xml.Job.Name)
    $querysessionurl = ("{0}?{1}" -f $spliturl[0],$arg)
    
    #execute the query
    $r_qsess = Invoke-WebRequest -Method Get -Headers @{$sessionheadername=$sessionid} -Uri $querysessionurl
    $r_qsess_xml = [xml]$r_qsess.Content
    $lastsession = $r_qsess_xml.QueryResult.Entities.BackupJobSessions.BackupJobSession

    #wait for it to be done
    if (@($lastsession).Count -eq 1) {
        while ( $lastsession.State -ne "Stopped") {
            $r_session = Invoke-WebRequest -Method Get -Headers @{$sessionheadername=$sessionid} -Uri $lastsession.Href
            $r_session_xml =  [xml]$r_session.Content
            $lastsession = $r_session_xml.BackupJobSession 
            write-host $lastsession.Progress
            Start-Sleep -Seconds 1
        }
        write-host $lastsession.Result
    }

    #logout
    $logofflink = $r_login_xml.LogonSession.Links.Link | ? { $_.type -match "LogonSession" }
    Invoke-WebRequest -Method Delete -Headers @{$sessionheadername=$sessionid} -Uri $logofflink.Href
}