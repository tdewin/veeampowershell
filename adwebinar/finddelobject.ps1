$delobject = "Cherrie Belcourt"


$searcher = New-Object System.DirectoryServices.DirectorySearcher -Property @{ 
    Filter = "(&(Name=$delobject*))"; 
    Tombstone = $true;
}
$searcher.PropertiesToLoad.AddRange(@("isdeleted","name","objectGUID","distinguishedname","usnchanged","usncreated"))

$searcher.Findall() | % { 
    $props = $_.Properties;

    $props.GetEnumerator() | Sort-Object -Property Key | % { 
        write-host -NoNewline ("{0,-20} : " -f $_.key)

        #can be multival
        $val = $_.value;
        $val | % {
            $str = $_

            $t = $_.gettype()
            if($t -eq [System.Byte[]]) {
               $str = [System.Guid]::new($_).ToString()
            } 
            
            write-host -NoNewline ("{0} " -f $str)
        }
        write-host ""
    } 
}

<#
Get-ADUser -LDAPFilter "(&(Name=$delobject*))" | Remove-ADUser
#>
