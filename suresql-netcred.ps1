param(
	$server = "localhost"
	$instance = "$server\MSSQLSERVER"
)

$connectionString = "Server=$instance;Integrated Security=True;"

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString

$failure = 1

$q = @'
SELECT name, database_id, state
FROM sys.databases ;
'@

try {
    $connection.Open()

    
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = $q

    $datatable = New-Object System.Data.DataTable
    $reader = $cmd.ExecuteReader()
    $datatable.Load($reader)

    $connection.Close()
    $allonline = $true
    $datatable | % {
        if ( $_[2] -eq 0 ) {
            write-host ("online : {0}" -f $_[0])
        } else {
            $allonline = $false
            #state codes : https://msdn.microsoft.com/en-us/library/ms178534.aspx
            write-host ("code {0} : {1}" -f $_[2],$_[0])
        }
    }
    if ($allonline) { $failure = 0; write-host "All online!" } 
    else { $failure = 1;write-host "Not online db detected" }
} catch {
    write-host ("Query failed or could not open connection {0} " -f $error[0])
    $failure = 1
} finally {
    $connection.Close()
}

#write-host $failure
#sleep -Seconds 5
exit $failure