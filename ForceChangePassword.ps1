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

foreach ($line in $csv)
    { 
    Set-ADUser -Identity $csv.name -ChangePasswordAtLogon $true -server $csv.domain
    }
