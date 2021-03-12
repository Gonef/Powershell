Function Get-FileName($directory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $directory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
    
}

$timestamp = get-date

$inputfile = Get-FileName ".\" 

$csv = Import-Csv $inputfile -Delimiter ";" 

foreach ($line in $csv){

try{
    Get-ADGroup -Identity $line.GroupName | Rename-ADObject -NewName $line.NewGroupName
    Get-ADGroup -Identity $line.GroupName | Set-Adgroup -Samaccountname $line.NewGroupName
    Write-Host " $line.GroupName was changed to $line.NewGroupName " -foregroundcolor green
    }
catch{
    Write-Host " $line.GroupName wasnt changed" -foregroundcolor red


    }

}
