Function Get-FileName($directory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $directory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
    
}

$inputfile = Get-FileName ".\" 

$input = Import-Csv $inputfile -Delimiter ";" 



foreach ($entry in $input)
    {

    $domain = $null
    $domain = $entry.DOMAIN
    $objectname = $entry.NAME


    if ($domain -eq "domainname")
    {
        $domain = "domainname"
    }

    elseif(!($domain.Contains('.')))
    {
        $domain = $domain + ".domainsufix"
    }


        try
        {
        Get-ADUser -Identity $entry.NAME -Server $domain -Properties EmployeeID | select SamAccountName, adminDisplayName, EmployeeID, @{n="owner";e={
            
            [String]$ownNumber = $PSITEM.EmployeeID
            while($ownNumber.Length -lt 6){
                $ownNumber = "0" + $ownNumber
            }
            Get-ADUser -Identity ("AA"+$ownNumber) -Server domainname | Select -ExpandProperty Name}}
        }
        
        catch [Microsoft.ActiveDirectory.Management.ADServerDownException]
        {
        Write-Host "Probably a typo in domain field in CSV entry for $domain\$objectname"
        }

        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            try{
                Get-ADGroup -Identity $entry.NAME -Server $domain -Properties adminDisplayName | select SamAccountName, adminDisplayName, EmployeeID, @{n="owner";e={
                
                [String]$ownNumber = $PSITEM.adminDisplayName
                while($ownNumber.Length -lt 6){
                    $ownNumber = "0" + $ownNumber
            }
                Get-ADUser -Identity ("AA"+$ownNumber) -Server domainname | Select -ExpandProperty Name}}
            }

            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
            {
                Write-Host "$objectname doesn't exist in $domain"
            }

        }
    
        catch 
        {
            Write-Host "Account/Group probably exist. Different error occured please contact Mateusz Juszczyk or last updater of script"
        }


    }
