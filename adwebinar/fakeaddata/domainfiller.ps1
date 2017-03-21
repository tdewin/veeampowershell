$global = "Global"
$minusers = 30
$maxusers = 60

$datafiles = "C:\Users\Administrator\Desktop\fakedata"
$oufile = ("{0}\{1}" -f $datafiles,"ou.txt")
$fnamefile = ("{0}\{1}" -f $datafiles,"fnames.txt")
$lnamefile = ("{0}\{1}" -f $datafiles,"lnames.txt")
$subgroupsfile = ("{0}\{1}" -f $datafiles,"subgroups.txt")

$ous = Get-Content -Path $oufile
$fnames = Get-Content -Path $fnamefile
$lnames = Get-Content -Path $lnamefile
$subgroups = Get-Content -Path $subgroupsfile

$domain = $(get-addomain)
$root = $domain.DistinguishedName

New-ADOrganizationalUnit -Name $global -Path $root
$globalou = Get-ADOrganizationalUnit -Filter {Name -eq $global}

new-gpo -name ("GPO $global") | new-gplink -target "ou=$global,$root"

$allgroups = @()

$notsecpass= "AllTheSame123" | ConvertTo-SecureString -AsPlainText   -Force

if ($globalou) {
    foreach ($ou in $ous) {
        if ($ou.Trim() -ne "") {
            write-host "Sub ou $ou"
            New-ADOrganizationalUnit -Name $ou -Path $globalou.DistinguishedName
            $subou = Get-ADOrganizationalUnit -Filter {Name -eq $ou}

            if($subou) {
                new-gpo -name ("GPO Sub $ou") | new-gplink -target $subou.DistinguishedName

                $ougroups = @()

                foreach($gr in $subgroups) {
                    if ($gr.Trim() -ne "") {
                        $groupname = ("{0} {1}" -f $ou,$gr.Trim())
                        write-host ("Making group $groupname")
                        New-ADGroup -Name $groupname -Path $subou.DistinguishedName -GroupScope Global -GroupCategory Security
                        $lgroup = Get-ADGroup -Filter {Name -eq $groupname}
                        $allgroups += $lgroup
                        $ougroups += $lgroup
                    }
                }

                $maingroupname = ("{0} All Users" -f $ou)
                New-ADGroup -Name $maingroupname -Path $subou.DistinguishedName -GroupScope Global -GroupCategory Security
                $maingroup = Get-ADGroup -Filter {Name -eq $maingroupname}

                $makeusers = Get-Random -Maximum $maxusers -Minimum $minusers
                for ($u=0;$u -lt $maxusers;$u++) {
                    $fname = $fnames[$(get-random -maximum $fnames.Count)]
                    $lname = $lnames[$(get-random -maximum $lnames.Count)]
                    $username = $($fname[0]+$lname).ToLower()

                    write-host "Making $username"
                    $upn = ("{0}@{1}" -f $username,$domain.Forest)
                    New-ADUser -AccountPassword $notsecpass -ChangePasswordAtLogon $false -DisplayName ("$fname $lname") -EmailAddress ("{0}.{1}@{2}" -f $fname,$lname,$domain.Forest) -City $ou -GivenName $fname -Name  ("$fname $lname") -Surname $lname -PasswordNeverExpires $true -Path $subou.DistinguishedName -SamAccountName $username -UserPrincipalName $upn
                    $aduser = Get-ADUser -Filter { UserPrincipalName -eq $upn}

                    $groupuser = $ougroups[$(get-random -maximum $ougroups.Count)]
                    Add-ADGroupMember -Members $aduser -Identity $groupuser
                    Add-ADGroupMember -Members $aduser -Identity $maingroup
                }

            }
        }
    }
}


