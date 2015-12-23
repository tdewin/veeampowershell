param(
	$server = "localhost",
    $instance = "MSSQLSERVER",
	$instancefull = "$server\$instance",
    $minimumdb = 4
)


$connectionString = "Server=$instancefull;Integrated Security=True;"

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString

$failure = 1

#ugly fix to touch all dbs, otherwise it shows corrupted db's as online :(
$useall = 'EXECUTE master.sys.sp_MSforeachdb ''USE [?];'''
$q = 'use master;SELECT name, state FROM sys.databases;'


try {
    $connection.Open()

    
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = $useall
    $cmd.ExecuteNonQuery()

    $cmd = $connection.CreateCommand()
    $cmd.CommandText = $q

    $reader = $cmd.ExecuteReader()
    $datatable = @()
    while($reader.Read())
    {
        $datatable += New-Object -TypeName psobject -Property @{name=$reader["name"];state=$reader["state"];}
    }

    $connection.Close()
    
    if($datatable.Count -ge $minimumdb) {
        $allonline = $true
        $off = @()
        $datatable | % {
            if ( $_.state -eq 0 ) {
                write-host ("online : {0}" -f $_.name)
            } else {
                $allonline = $false
                #state codes : https://msdn.microsoft.com/en-us/library/ms178534.aspx
                write-host ("code {0} : {1}" -f $_.state,$_.name)
                $off += $_.name
            }
        }
        if ($allonline) { $failure = 0; write-host ("All {0} databases online !" -f $datatable.count) } 
        else { $failure = 1;write-host ("Not online db detected : {0}" -f ($off -join ",")) }
    } else {
        $failure = 1;write-host ("Query should at least give back {0} databases" -f $minimumdb)
    }
} catch {
    write-host ("Query failed or could not open connection {1} : {0} " -f $error[0],$connectionString)
    $failure = 1
} finally {
    $connection.Close()
}

write-host $failure
sleep -Seconds 5
exit $failure